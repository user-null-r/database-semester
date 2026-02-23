# Процедуры
## Процедура 1 enroll_user_in_flow(p_user_id, p_flow_id)
Записывает студента в поток.
```postgresql
CREATE OR REPLACE PROCEDURE enroll_user_in_flow(
    p_user_id BIGINT,
    p_flow_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exists INT;
    v_status VARCHAR;
    v_max INT;
    v_current INT;
    v_discipline_id BIGINT;
BEGIN
    -- Проверяем, есть ли пользователь
    PERFORM 1 FROM "user" WHERE id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    -- Проверяем статус потока
    SELECT status, max_students INTO v_status, v_max
    FROM flow WHERE id = p_flow_id;

    IF v_status <> 'active' THEN
        RAISE EXCEPTION 'Flow % is not active', p_flow_id;
    END IF;

    -- Проверяем, не записан ли уже
    SELECT COUNT(*) INTO v_exists
    FROM enrollment
    WHERE user_id = p_user_id AND flow_id = p_flow_id;

    IF v_exists > 0 THEN
        RAISE EXCEPTION 'User % already enrolled in flow %', p_user_id, p_flow_id;
    END IF;

    -- Проверяем наличие мест
    SELECT COUNT(*) INTO v_current
    FROM enrollment WHERE flow_id = p_flow_id;

    IF v_current >= v_max THEN
        RAISE EXCEPTION 'Flow % is full', p_flow_id;
    END IF;

    -- Берем одну дисциплину потока (каноничная схема допускает одну запись enrollment на пару user/flow)
    SELECT id INTO v_discipline_id
    FROM discipline
    WHERE flow_id = p_flow_id
    ORDER BY id
    LIMIT 1;

    IF v_discipline_id IS NULL THEN
        RAISE EXCEPTION 'Flow % has no linked discipline', p_flow_id;
    END IF;

    -- Записываем пользователя
    INSERT INTO enrollment(user_id, discipline_id, flow_id, enrolled_at, status)
    VALUES (p_user_id, v_discipline_id, p_flow_id, now(), 'enrolled');

    RAISE NOTICE 'User % successfully enrolled in flow %', p_user_id, p_flow_id;
END;
$$;
```
```postgresql
DELETE FROM enrollment WHERE user_id = 2 AND flow_id = 1;

CALL enroll_user_in_flow(2, 1);

SELECT * FROM enrollment WHERE user_id = 2 AND flow_id = 1;
```
| id | user\_id | discipline\_id | flow\_id | enrolled\_at | dropped\_at | attendance\_pct | current\_score | final\_grade | status | created\_at | updated\_at |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 32 | 15 | 3 | 4 | 2025-11-25 18:23:51.815131 +00:00 | null | null | null | null | enrolled | 2025-11-25 18:23:51.815131 +00:00 | 2025-11-25 18:23:51.815131 +00:00 |

## Процедура 2 close_flow_and_finalize_grades(p_flow_id)
- закрывает поток
- вычисляет финальные оценки по формуле
- устанавливает final_grade для студентов
- деактивирует все дисциплины потока
```postgresql
CREATE OR REPLACE PROCEDURE close_flow_and_finalize_grades(
    p_flow_id BIGINT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_enrollment RECORD;
    v_score      NUMERIC;
BEGIN
    -- Закрываем поток
    UPDATE flow
    SET status     = 'closed',
        updated_at = now()
    WHERE id = p_flow_id;

    -- Закрываем дисциплины
    UPDATE discipline
    SET status     = 'closed',
        updated_at = now()
    WHERE flow_id = p_flow_id;

    -- Обрабатываем студентов
    FOR v_enrollment IN
        SELECT id, user_id, current_score, attendance_pct
        FROM enrollment
        WHERE flow_id = p_flow_id
          AND status IN ('enrolled', 'active')
        LOOP
            -- Формула финального балла
            v_score := (COALESCE(v_enrollment.current_score, 0) * 0.8) +
                       (COALESCE(v_enrollment.attendance_pct, 0) * 0.2);

            UPDATE enrollment
            SET final_grade = CASE
                                  WHEN v_score >= 86 THEN 'A'
                                  WHEN v_score >= 71 THEN 'B'
                                  WHEN v_score >= 65 THEN 'C'
                                  WHEN v_score >= 56 THEN 'D'
                                  ELSE 'F'
                END,
                status      = 'completed'
            WHERE id = v_enrollment.id;
        END LOOP;

    RAISE NOTICE 'Flow % successfully closed and grades finalized.', p_flow_id;
END;
$$;
```
```postgresql
CALL close_flow_and_finalize_grades(3);
SELECT user_id, final_grade FROM enrollment WHERE flow_id = 3;
```
| user\_id | final\_grade |
| :--- | :--- |
| 1 | A |
| 2 | A |
| 3 | B |
| 5 | A |
| 6 | B |
| 7 | A |
| 8 | A |
| 9 | B |
| 10 | A |
| 11 | A |
| 12 | A |
| 13 | A |
| 14 | B |

## Процедура 3 assign_teacher_to_discipline(p_teacher_id, p_discipline_id)
Добавляет преподавателя к дисциплине + проверяет на дубликат.
```postgresql
CREATE OR REPLACE PROCEDURE assign_teacher_to_discipline(
    p_teacher_id BIGINT,
    p_discipline_id BIGINT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_exists INT;
BEGIN
    SELECT COUNT(*)
    INTO v_exists
    FROM discipline_teacher
    WHERE teacher_id = p_teacher_id
      AND discipline_id = p_discipline_id;

    IF v_exists > 0 THEN
        RAISE NOTICE 'Teacher already assigned';
        RETURN;
    END IF;

    INSERT INTO discipline_teacher(teacher_id, discipline_id)
    VALUES (p_teacher_id, p_discipline_id);

    RAISE NOTICE 'Teacher % assigned to discipline %', p_teacher_id, p_discipline_id;
END;
$$;
```
```postgresql
DELETE FROM discipline_teacher WHERE teacher_id = 3 AND discipline_id = 1;

CALL assign_teacher_to_discipline(3, 1);
SELECT * FROM discipline_teacher WHERE teacher_id = 3;
```
| discipline\_id | teacher\_id |
| :--- | :--- |
| 1 | 16 |
| 3 | 16 |

# Функции
## Функция 1: Получить количество студентов в потоке
```postgresql
CREATE OR REPLACE FUNCTION count_students_in_flow(p_flow_id BIGINT)
    RETURNS INT
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN (SELECT COUNT(*)
            FROM enrollment
            WHERE flow_id = p_flow_id);

END;
$$;
```
```postgresql
SELECT id, count_students_in_flow(id) FROM flow
```
| id | count\_students\_in\_flow |
| :--- | :--- |
| 2 | 0 |
| 4 | 5 |
| 5 | 1 |
| 1 | 0 |
| 3 | 13 |

## Функция 2: Проверка, преподает ли пользователь хотя бы одну дисциплину
```postgresql
CREATE OR REPLACE FUNCTION is_teaching(p_user_id BIGINT)
    RETURNS BOOLEAN
    LANGUAGE plpgsql AS
$$
BEGIN
    RETURN EXISTS(SELECT 1
                  FROM discipline_teacher
                  WHERE teacher_id = p_user_id);

END;
$$;
```
```postgresql
SELECT id, is_teaching(id) FROM "user";
```
| id  | is\_teaching |
|:----|:-------------|
| 1   | false        |
| 2   | false        |
| ... | ...          |
| 15  | false        |
| 16  | true         |
| 17  | true         |
| 18  | true         |
| 19  | true         |


## Функция 3: средний балл студента по всем дисциплинам
```postgresql
CREATE OR REPLACE FUNCTION student_avg_score(p_user_id BIGINT)
    RETURNS NUMERIC(6, 2) AS
$$
BEGIN
    RETURN (SELECT CASE
                       WHEN COUNT(*) = 0 THEN 0
                       ELSE AVG(current_score)
                       END
            FROM enrollment
            WHERE user_id = p_user_id
              AND current_score IS NOT NULL);
END;
$$ LANGUAGE plpgsql STABLE;

SELECT id, student_avg_score(id) FROM "user";
```
| id | student\_avg\_score |
| :--- | :--- |
| 1 | 86.25 |
| 2 | 86.75 |
| 3 | 78 |
| 4 | 91.25 |
| 5 | 85 |
| 6 | 82.5 |
| 7 | 88 |
| 8 | 89 |
| 9 | 84 |
| 10 | 90 |
| 11 | 86 |
| 12 | 88.5 |
| 13 | 93 |
| 14 | 83 |

# Функции с переменными
## Функция 1: возвращает нагрузку потока в часах, суммируя длительность всех занятий.
```postgresql
CREATE OR REPLACE FUNCTION calc_flow_load(p_flow_id BIGINT)
    RETURNS INT
    LANGUAGE plpgsql AS
$$
DECLARE
    v_total   INT := 0;
    v_lesson  RECORD;
    v_minutes INT;
BEGIN
    FOR v_lesson IN
        SELECT start_at, end_at FROM lesson WHERE flow_id = p_flow_id
        LOOP
            v_minutes := EXTRACT(EPOCH FROM (v_lesson.end_at - v_lesson.start_at)) / 60;
            v_total := v_total + v_minutes;
        END LOOP;

    RETURN v_total;
END;
$$;

SELECT id, calc_flow_load(id) FROM flow;
```
| id | calc\_flow\_load |
| :--- | :--- |
| 2 | 0 |
| 4 | 420 |
| 5 | 180 |
| 1 | 0 |
| 3 | 270 |

## Функция 2: рейтинг преподавателя = средняя оценка его дисциплин
```postgresql
CREATE OR REPLACE FUNCTION teacher_rating(p_teacher_id BIGINT)
    RETURNS NUMERIC(6, 2) AS
$$
DECLARE
    v_discipline_id BIGINT;
    v_avg_score     NUMERIC(6, 2);
    v_total         NUMERIC(10, 2) := 0;
    v_count         INT            := 0;
BEGIN
    FOR v_discipline_id IN
        SELECT id FROM discipline WHERE lecturer_id = p_teacher_id
        LOOP
            SELECT AVG(current_score)
            INTO v_avg_score
            FROM enrollment
            WHERE discipline_id = v_discipline_id
              AND current_score IS NOT NULL;

            IF v_avg_score IS NOT NULL THEN
                v_total := v_total + v_avg_score;
                v_count := v_count + 1;
            END IF;
        END LOOP;

    IF v_count = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND(v_total / v_count, 2);
END;
$$ LANGUAGE plpgsql;

SELECT teacher_id, teacher_rating(teacher_id) FROM discipline_teacher;
```
| teacher\_id | teacher\_rating |
| :--- | :--- |
| 16 | 86.58 |
| 17 | 81.83 |
| 18 | 88 |
| 19 | 94.5 |
| 16 | 86.58 |

## Функция 3: Возвращает агрегированный отчёт по студентам потока:
- средняя посещаемость
- средний балл
- число сдавших
- число проваливших
- Возвращает JSON.
```postgresql
CREATE OR REPLACE FUNCTION get_flow_student_summary(p_flow_id BIGINT)
    RETURNS JSON
    LANGUAGE plpgsql AS
$$
DECLARE
    v_avg_att   NUMERIC;
    v_avg_score NUMERIC;
    v_passed    INT;
    v_failed    INT;
BEGIN
    SELECT AVG(attendance_pct), AVG(current_score)
    INTO v_avg_att, v_avg_score
    FROM enrollment
    WHERE flow_id = p_flow_id;

    SELECT COUNT(*)
    INTO v_passed
    FROM enrollment
    WHERE flow_id = p_flow_id
      AND final_grade IN ('A', 'B', 'C', 'D');

    SELECT COUNT(*)
    INTO v_failed
    FROM enrollment
    WHERE flow_id = p_flow_id
      AND final_grade = 'F';

    RETURN json_build_object(
            'average_attendance', v_avg_att,
            'average_score', v_avg_score,
            'passed', v_passed,
            'failed', v_failed
           );
END;
$$;

SELECT id, get_flow_student_summary(id) FROM flow;
```
| id | get\_flow\_student\_summary |
| :--- | :--- |
| 2 | {"average\_attendance" : null, "average\_score" : null, "passed" : 0, "failed" : 0} |
| 4 | {"average\_attendance" : 89.1250000000000000, "average\_score" : 83.3750000000000000, "passed" : 4, "failed" : 0} |
| 5 | {"average\_attendance" : 98.0000000000000000, "average\_score" : 94.5000000000000000, "passed" : 1, "failed" : 0} |
| 1 | {"average\_attendance" : null, "average\_score" : null, "passed" : 0, "failed" : 0} |
| 3 | {"average\_attendance" : 90.8846153846153846, "average\_score" : 86.5769230769230769, "passed" : 13, "failed" : 0} |


# DO
## Пересчёт баллов студентам с шагом по 1 дисциплине
```postgresql
DO
$$
    DECLARE
        v_id  BIGINT := 1;
        v_max BIGINT;
    BEGIN
        SELECT MAX(id) INTO v_max FROM discipline;

        WHILE v_id <= v_max
            LOOP
                UPDATE enrollment
                SET current_score = COALESCE(current_score, 0) + 1
                WHERE discipline_id = v_id;

                v_id := v_id + 1;
            END LOOP;
    END;
$$;
```
## Генерация уроков на каждый день недели
```postgresql
DO
$$
    DECLARE
        day_offset INT := 1;
    BEGIN
        WHILE day_offset <= 7
            LOOP
                INSERT INTO lesson(flow_id, type, topic, start_at, end_at, status)
                VALUES (1,
                        'lecture',
                        'Auto topic ' || day_offset,
                        NOW() + (day_offset || ' days')::INTERVAL,
                        NOW() + (day_offset || ' days 1 hour')::INTERVAL,
                        'scheduled');

                day_offset := day_offset + 1;
            END LOOP;
    END;
$$;
```
## EXCEPTION division_by_zero
```postgresql
DO
$$
    DECLARE
        v_flow_id        BIGINT := 1;
        v_total_students INT;
        v_sum_attendance NUMERIC;
        v_avg_attendance NUMERIC;
    BEGIN
        -- Считаем количество студентов и суммарную посещаемость
        SELECT COUNT(*),
               COALESCE(SUM(attendance_pct), 0)
        INTO
            v_total_students,
            v_sum_attendance
        FROM enrollment
        WHERE flow_id = v_flow_id;

        BEGIN
            -- Возможно деление на ноль, если нет студентов
            v_avg_attendance := v_sum_attendance / v_total_students;

            RAISE NOTICE 'Средняя посещаемость потока %: %%%',
                v_flow_id, ROUND(v_avg_attendance, 2);

        EXCEPTION
            WHEN division_by_zero THEN
                RAISE NOTICE 'Невозможно вычислить среднюю посещаемость — в потоке % нет студентов.', v_flow_id;
        END;
    END;
$$;
```

## EXCEPTION unique_violation
```postgresql
DO
$$
    BEGIN
        INSERT INTO role(code, name, status) VALUES ('admin', 'Administrator', 'active');
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'Role already exists';
    END;
$$;
```
