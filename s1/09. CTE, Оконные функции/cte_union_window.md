# CTE


### 1. Список преподавателей с количеством дисциплин

```postgresql
WITH teacher_disciplines AS (
    SELECT 
        lecturer_id,
        COUNT(*) AS discipline_count
    FROM discipline
    WHERE status = 'active'
    GROUP BY lecturer_id
)
SELECT 
    u.full_name AS teacher_name,
    td.discipline_count
FROM teacher_disciplines td
JOIN "user" u ON u.id = td.lecturer_id
ORDER BY td.discipline_count DESC;
```

| teacher\_name | discipline\_count |
| :--- | :--- |
| Смирнов Петр Николаевич | 1 |
| Волкова Елена Александровна | 1 |
| Морозов Дмитрий Сергеевич | 1 |
| Новикова Ольга Ивановна | 1 |


### 2. Активные потоки и количество студентов
```postgresql
WITH flow_enrollments AS (
    SELECT 
        flow_id,
        COUNT(DISTINCT user_id) AS student_count
    FROM enrollment
    WHERE status = 'active'
    GROUP BY flow_id
)
SELECT 
    f.code AS flow_code,
    f.title AS flow_title,
    fe.student_count
FROM flow_enrollments fe
JOIN flow f ON f.id = fe.flow_id
ORDER BY fe.student_count DESC;
```
| flow\_code | flow\_title | student\_count |
| :--- | :--- | :--- |
| MATH101-F23 | Математический анализ, поток 2023 | 13 |
| CS201-F23 | Программирование на C#, поток 2023 | 4 |
| HIST101-F23 | История России, поток 2023 | 2 |


### 3. Иерархия подразделений
```postgresql
WITH RECURSIVE unit_hierarchy AS (
    SELECT 
        id,
        name,
        parent_id,
        1 AS level
    FROM unit
    WHERE parent_id IS NULL
    UNION ALL
    SELECT 
        u.id,
        u.name,
        u.parent_id,
        uh.level + 1
    FROM unit u
    JOIN unit_hierarchy uh ON u.parent_id = uh.id
)
SELECT 
    LPAD('', (level - 1) * 4, ' ') || name AS indented_name,
    level
FROM unit_hierarchy
ORDER BY level, name;
```
<table border="1" style="border-collapse:collapse">
<tr><th>indented_name</th><th>level</th></tr>
<tr><td>Институт гуманитарных наук</td><td>1</td></tr>
<tr><td>Институт математики и информатики</td><td>1</td></tr>
<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;Кафедра информатики</td><td>2</td></tr>
<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;Кафедра истории</td><td>2</td></tr>
<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;Кафедра математического анализа</td><td>2</td></tr>
</table>

### 4. Средняя успеваемость по дисциплинам
```postgresql
WITH discipline_scores AS (
    SELECT 
        discipline_id,
        AVG(current_score) AS avg_score
    FROM enrollment
    WHERE current_score IS NOT NULL
    GROUP BY discipline_id
)
SELECT 
    d.code,
    d.title,
    ds.avg_score
FROM discipline_scores ds
JOIN discipline d ON d.id = ds.discipline_id
ORDER BY ds.avg_score DESC;
```
| code | title | avg\_score |
| :--- | :--- | :--- |
| HIST101 | История России | 93.25 |
| CS202 | Базы данных | 88 |
| MATH101 | Математический анализ | 86.5769230769230769 |
| CS201 | Программирование на C# | 81.8333333333333333 |


### 5. Загрузка преподавателей (число дисциплин и экзаменов)
```postgresql
WITH teacher_disciplines AS (
    SELECT
        lecturer_id AS teacher_id,
        COUNT(*) AS discipline_count
    FROM discipline
    GROUP BY lecturer_id
),
teacher_exams AS (
    SELECT
        proctor_id AS teacher_id,
        COUNT(*) AS exam_count
    FROM exam
    GROUP BY proctor_id
)
SELECT
    u.full_name,
    COALESCE(td.discipline_count, 0) AS disciplines,
    COALESCE(te.exam_count, 0) AS exams,
    (COALESCE(td.discipline_count, 0) + COALESCE(te.exam_count, 0)) AS total_load
FROM "user" u
LEFT JOIN teacher_disciplines td ON td.teacher_id = u.id
LEFT JOIN teacher_exams te ON te.teacher_id = u.id
WHERE td.discipline_count IS NOT NULL OR te.exam_count IS NOT NULL
ORDER BY total_load DESC;
```
| full\_name | disciplines | exams | total\_load |
| :--- | :--- | :--- | :--- |
| Новикова Ольга Ивановна | 1 | 2 | 3 |
| Волкова Елена Александровна | 1 | 2 | 3 |
| Смирнов Петр Николаевич | 1 | 2 | 3 |
| Морозов Дмитрий Сергеевич | 1 | 2 | 3 |

# UNION

### 1. Все email пользователей и подразделений
```postgresql
SELECT email FROM "user"
WHERE email IS NOT NULL
UNION
SELECT email FROM unit
WHERE email IS NOT NULL
```
| email                          |
|:-------------------------------|
| smirnov@teacher.university.edu |
| pavlova@student.university.edu |
| math@university.edu            |
| igh@university.edu             |
| cs@university.edu              |
| ...                            |

### 2. Все активные дисциплины и потоки
```postgresql
SELECT code, title FROM discipline WHERE status = 'active'
UNION
SELECT code, title FROM flow WHERE status = 'active';
```
| code | title |
| :--- | :--- |
| CS201 | Программирование на C# |
| CS201-F22 | Программирование на C#, поток 2022 |
| CS201-F23 | Программирование на C#, поток 2023 |
| CS202 | Базы данных |
| HIST101 | История России |
| HIST101-F23 | История России, поток 2023 |
| MATH101 | Математический анализ |
| MATH101-F22 | Математический анализ, поток 2022 |
| MATH101-F23 | Математический анализ, поток 2023 |

### 3. Все активные аудитории и онлайн-занятия
```postgresql
SELECT building AS location, room_number AS identifier FROM classroom WHERE status = 'active'
UNION
SELECT 'online' AS location, online_link AS identifier FROM lesson WHERE online_link IS NOT NULL;
```
| location | identifier |
| :--- | :--- |
| Главный корпус | 205 |
| Главный корпус | 101 |
| Главный корпус | 310 |
| online | https://telemost.yandex.ru/abvgd |
| Корпус Б | 301 |
| Корпус Б | 102 |
| Корпус Б | 201 |

# INTERSECT
### 1. Преподаватели, которые также являются прокторами на экзаменах
```postgresql
SELECT DISTINCT lecturer_id FROM discipline WHERE lecturer_id IS NOT NULL
INTERSECT
SELECT DISTINCT proctor_id FROM exam WHERE proctor_id IS NOT NULL;
```
| lecturer\_id |
| :--- |
| 16 |
| 19 |
| 17 |
| 18 |

### 2. Активные пользователи, которые также являются преподавателями
```postgresql
SELECT id FROM "user" WHERE status = 'active'
INTERSECT
SELECT DISTINCT lecturer_id FROM discipline WHERE lecturer_id IS NOT NULL;
```
| id |
| :--- |
| 19 |
| 17 |
| 18 |
| 16 |

### 3. Аудитории, где проходят и уроки, и экзамены
```postgresql
SELECT classroom_id FROM lesson_classroom
INTERSECT
SELECT classroom_id FROM exam_classroom;
```
| classroom\_id |
| :--- |
| 3 |
| 2 |
| 1 |

# EXCEPT
### 1. Потоки без дисциплин
```postgresql
SELECT id FROM flow
EXCEPT
SELECT DISTINCT flow_id FROM discipline WHERE flow_id IS NOT NULL;
```
| id |
| :--- |
| 2 |
| 1 |

### 2. Аудитории, не задействованные в уроках
```postgresql
SELECT id FROM classroom
EXCEPT
SELECT DISTINCT classroom_id FROM lesson_classroom;
```
| id |
| :--- |
| 5 |
| 4 |

### 3. Активные пользователи, не входящие ни в один поток
```postgresql
SELECT id FROM "user" WHERE status = 'active'
EXCEPT
SELECT DISTINCT user_id FROM enrollment;
```
| id |
| :--- |
| 19 |
| 17 |
| 18 |
| 16 |

# PARTITION BY
### 1. Средний балл студентов в дисциплине
```postgresql
SELECT 
    e.user_id,
    e.discipline_id,
    e.current_score,
    AVG(e.current_score) OVER (PARTITION BY e.discipline_id) AS avg_discipline_score
FROM enrollment e
WHERE e.current_score IS NOT NULL;
```
| user\_id | discipline\_id | current\_score | avg\_discipline\_score |
| :--- | :--- | :--- | :--- |
| 1 | 1 | 87.50 | 86.5769230769230769 |
| 2 | 1 | 91.00 | 86.5769230769230769 |
| 3 | 1 | 78.00 | 86.5769230769230769 |
| 5 | 1 | 85.00 | 86.5769230769230769 |
| 6 | 1 | 82.50 | 86.5769230769230769 |
| 7 | 1 | 88.00 | 86.5769230769230769 |
| 8 | 1 | 89.00 | 86.5769230769230769 |
| 9 | 1 | 84.00 | 86.5769230769230769 |
| 10 | 1 | 90.00 | 86.5769230769230769 |
| 11 | 1 | 86.00 | 86.5769230769230769 |
| 12 | 1 | 88.50 | 86.5769230769230769 |
| 13 | 1 | 93.00 | 86.5769230769230769 |
| 14 | 1 | 83.00 | 86.5769230769230769 |
| 1 | 2 | 85.00 | 81.8333333333333333 |
| 2 | 2 | 82.50 | 81.8333333333333333 |
| 3 | 2 | 78.00 | 81.8333333333333333 |
| 4 | 3 | 88.00 | 88 |
| 4 | 4 | 94.50 | 93.25 |
| 15 | 4 | 92.00 | 93.25 |

### 2. Количество студентов в потоке
```postgresql
SELECT 
    e.user_id,
    e.flow_id,
    COUNT(*) OVER (PARTITION BY e.flow_id) AS total_students_in_flow
FROM enrollment e;
```
| user\_id | flow\_id | total\_students\_in\_flow |
| :--- | :--- | :--- |
| 1 | 3 | 13 |
| 2 | 3 | 13 |
| 3 | 3 | 13 |
| 5 | 3 | 13 |
| 6 | 3 | 13 |
| 7 | 3 | 13 |
| 8 | 3 | 13 |
| 9 | 3 | 13 |
| 10 | 3 | 13 |
| 11 | 3 | 13 |
| 12 | 3 | 13 |
| 13 | 3 | 13 |
| 14 | 3 | 13 |
| 1 | 4 | 4 |
| 2 | 4 | 4 |
| 3 | 4 | 4 |
| 4 | 4 | 4 |
| 4 | 5 | 2 |
| 15 | 5 | 2 |

# PARTITION BY + ORDER BY
### 1. Нумерация занятий внутри потока
```postgresql
SELECT 
    l.flow_id,
    l.id AS lesson_id,
    l.topic,
    l.start_at,
    ROW_NUMBER() OVER (PARTITION BY l.flow_id ORDER BY l.start_at) AS lesson_number
FROM lesson l
WHERE l.flow_id IS NOT NULL;
```
| flow\_id | lesson\_id | topic | start\_at | lesson\_number |
| :--- | :--- | :--- | :--- | :--- |
| 3 | 1 | Введение в математический анализ. Пределы | 2023-09-05 06:00:00.000000 +00:00 | 1 |
| 3 | 2 | Решение задач на пределы | 2023-09-07 06:00:00.000000 +00:00 | 2 |
| 3 | 3 | Производные функции | 2023-09-12 06:00:00.000000 +00:00 | 3 |
| 4 | 4 | Введение в C#. Основы синтаксиса | 2023-09-04 11:00:00.000000 +00:00 | 1 |
| 4 | 5 | Практическая работа: Переменные и типы данных | 2023-09-06 11:00:00.000000 +00:00 | 2 |
| 4 | 6 | ООП в C# | 2023-09-11 11:00:00.000000 +00:00 | 3 |
| 4 | 9 | Практическая работа: Работа с БД | 2023-09-13 11:00:00.000000 +00:00 | 4 |
| 5 | 7 | Древняя Русь | 2023-09-05 08:00:00.000000 +00:00 | 1 |
| 5 | 8 | Обсуждение эпохи Петра I | 2023-09-07 08:00:00.000000 +00:00 | 2 |

### 2. Рейтинг студентов по баллу в дисциплине
```postgresql
SELECT 
    e.discipline_id,
    e.user_id,
    e.current_score,
    RANK() OVER (PARTITION BY e.discipline_id ORDER BY e.current_score DESC) AS rank_in_discipline
FROM enrollment e
WHERE e.current_score IS NOT NULL;
```
| discipline\_id | user\_id | current\_score | rank\_in\_discipline |
| :--- | :--- | :--- | :--- |
| 1 | 13 | 93.00 | 1 |
| 1 | 2 | 91.00 | 2 |
| 1 | 10 | 90.00 | 3 |
| 1 | 8 | 89.00 | 4 |
| 1 | 12 | 88.50 | 5 |
| 1 | 7 | 88.00 | 6 |
| 1 | 1 | 87.50 | 7 |
| 1 | 11 | 86.00 | 8 |
| 1 | 5 | 85.00 | 9 |
| 1 | 9 | 84.00 | 10 |
| 1 | 14 | 83.00 | 11 |
| 1 | 6 | 82.50 | 12 |
| 1 | 3 | 78.00 | 13 |
| 2 | 1 | 85.00 | 1 |
| 2 | 2 | 82.50 | 2 |
| 2 | 3 | 78.00 | 3 |
| 3 | 4 | 88.00 | 1 |
| 4 | 4 | 94.50 | 1 |
| 4 | 15 | 92.00 | 2 |

# ROWS
### 1. Скользящее среднее посещаемости по урокам в потоке

Считает среднюю посещаемость за последние 3 занятия (в пределах потока).
```postgresql
SELECT 
    l.flow_id,
    l.start_at,
    e.attendance_pct,
    AVG(e.attendance_pct) OVER (
        PARTITION BY l.flow_id 
        ORDER BY l.start_at
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_attendance
FROM lesson l
JOIN enrollment e ON e.flow_id = l.flow_id
WHERE e.attendance_pct IS NOT NULL
ORDER BY l.flow_id, l.start_at
LIMIT 10;
```
| flow\_id | start\_at | attendance\_pct | moving\_avg\_attendance |
| :--- | :--- | :--- | :--- |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 94.00 | 94 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 95.50 | 94.75 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 93.00 | 94.1666666666666667 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 87.00 | 91.8333333333333333 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 88.00 | 89.3333333333333333 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 91.00 | 88.6666666666666667 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 88.50 | 89.1666666666666667 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 92.50 | 90.6666666666666667 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 92.00 | 91 |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 90.00 | 91.5 |

### 2. Кумулятивное количество занятий в потоке

Считает, сколько уроков прошло к данному моменту (накопительно).
```postgresql
SELECT 
    flow_id,
    start_at,
    COUNT(*) OVER (
        PARTITION BY flow_id 
        ORDER BY start_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_lessons
FROM lesson
WHERE flow_id IS NOT NULL
ORDER BY flow_id, start_at;
```
| flow\_id | start\_at | cumulative\_lessons |
| :--- | :--- | :--- |
| 3 | 2023-09-05 06:00:00.000000 +00:00 | 1 |
| 3 | 2023-09-07 06:00:00.000000 +00:00 | 2 |
| 3 | 2023-09-12 06:00:00.000000 +00:00 | 3 |
| 4 | 2023-09-04 11:00:00.000000 +00:00 | 1 |
| 4 | 2023-09-06 11:00:00.000000 +00:00 | 2 |
| 4 | 2023-09-11 11:00:00.000000 +00:00 | 3 |
| 4 | 2023-09-13 11:00:00.000000 +00:00 | 4 |
| 5 | 2023-09-05 08:00:00.000000 +00:00 | 1 |
| 5 | 2023-09-07 08:00:00.000000 +00:00 | 2 |


# RANGE

### 1. Кумулятивный процент студентов по баллу

Показывает, какой процент студентов набрал меньше или равно данного балла в дисциплине.
```postgresql
SELECT 
    discipline_id,
    user_id,
    current_score,
    100.0 * COUNT(*) OVER (
        PARTITION BY discipline_id
        ORDER BY current_score
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) / COUNT(*) OVER (PARTITION BY discipline_id) AS percentile
FROM enrollment
WHERE current_score IS NOT NULL
ORDER BY discipline_id, current_score;
```
| discipline\_id | user\_id | current\_score | percentile |
| :--- | :--- | :--- | :--- |
| 1 | 3 | 78.00 | 7.6923076923076923 |
| 1 | 6 | 82.50 | 15.3846153846153846 |
| 1 | 14 | 83.00 | 23.0769230769230769 |
| 1 | 9 | 84.00 | 30.7692307692307692 |
| 1 | 5 | 85.00 | 38.4615384615384615 |
| 1 | 11 | 86.00 | 46.1538461538461538 |
| 1 | 1 | 87.50 | 53.8461538461538462 |
| 1 | 7 | 88.00 | 61.5384615384615385 |
| 1 | 12 | 88.50 | 69.2307692307692308 |
| 1 | 8 | 89.00 | 76.9230769230769231 |
| 1 | 10 | 90.00 | 84.6153846153846154 |
| 1 | 2 | 91.00 | 92.3076923076923077 |
| 1 | 13 | 93.00 | 100 |
| 2 | 3 | 78.00 | 33.3333333333333333 |
| 2 | 2 | 82.50 | 66.6666666666666667 |
| 2 | 1 | 85.00 | 100 |
| 3 | 4 | 88.00 | 100 |
| 4 | 15 | 92.00 | 50 |
| 4 | 4 | 94.50 | 100 |

### 2. Средний балл в диапазоне ±10 от текущего

Для каждого студента показывает средний балл других студентов, находящихся в пределах ±10 баллов от его текущего.

```postgresql
SELECT 
    discipline_id,
    user_id,
    current_score,
    AVG(current_score) OVER (
        PARTITION BY discipline_id
        ORDER BY current_score
        RANGE BETWEEN 10 PRECEDING AND 10 FOLLOWING
    ) AS avg_nearby_scores
FROM enrollment
WHERE current_score IS NOT NULL
ORDER BY discipline_id, current_score;
```
| discipline\_id | user\_id | current\_score | avg\_nearby\_scores |
| :--- | :--- | :--- | :--- |
| 1 | 3 | 78.00 | 84.25 |
| 1 | 6 | 82.50 | 86.0416666666666667 |
| 1 | 14 | 83.00 | 86.5769230769230769 |
| 1 | 9 | 84.00 | 86.5769230769230769 |
| 1 | 5 | 85.00 | 86.5769230769230769 |
| 1 | 11 | 86.00 | 86.5769230769230769 |
| 1 | 1 | 87.50 | 86.5769230769230769 |
| 1 | 7 | 88.00 | 86.5769230769230769 |
| 1 | 12 | 88.50 | 87.2916666666666667 |
| 1 | 8 | 89.00 | 87.2916666666666667 |
| 1 | 10 | 90.00 | 87.2916666666666667 |
| 1 | 2 | 91.00 | 87.2916666666666667 |
| 1 | 13 | 93.00 | 87.7272727272727273 |
| 2 | 3 | 78.00 | 81.8333333333333333 |
| 2 | 2 | 82.50 | 81.8333333333333333 |
| 2 | 1 | 85.00 | 81.8333333333333333 |
| 3 | 4 | 88.00 | 88 |
| 4 | 15 | 92.00 | 93.25 |
| 4 | 4 | 94.50 | 93.25 |

## ROW_NUMBER()
### Список студентов с их порядковым номером в дисциплине
```postgresql
SELECT 
    discipline_id,
    user_id,
    ROW_NUMBER() OVER (PARTITION BY discipline_id ORDER BY user_id) AS student_number
FROM enrollment
ORDER BY discipline_id, student_number;
```
| discipline\_id | user\_id | student\_number |
| :--- | :--- | :--- |
| 1 | 1 | 1 |
| 1 | 2 | 2 |
| 1 | 3 | 3 |
| 1 | 5 | 4 |
| 1 | 6 | 5 |
| 1 | 7 | 6 |
| 1 | 8 | 7 |
| 1 | 9 | 8 |
| 1 | 10 | 9 |
| 1 | 11 | 10 |
| 1 | 12 | 11 |
| 1 | 13 | 12 |
| 1 | 14 | 13 |
| 2 | 1 | 1 |
| 2 | 2 | 2 |
| 2 | 3 | 3 |
| 3 | 4 | 1 |
| 4 | 4 | 1 |
| 4 | 15 | 2 |

## RANK()
### Рейтинг студентов по текущему баллу
```postgresql
SELECT 
    discipline_id,
    user_id,
    current_score,
    RANK() OVER (PARTITION BY discipline_id ORDER BY current_score DESC) AS rank_in_discipline
FROM enrollment
WHERE current_score IS NOT NULL
ORDER BY discipline_id, rank_in_discipline;
```
| discipline\_id | user\_id | current\_score | rank\_in\_discipline |
| :--- | :--- | :--- | :--- |
| 1 | 13 | 93.00 | 1 |
| 1 | 2 | 91.00 | 2 |
| 1 | 10 | 90.00 | 3 |
| 1 | 8 | 89.00 | 4 |
| 1 | 12 | 88.50 | 5 |
| 1 | 7 | 88.00 | 6 |
| 1 | 1 | 87.50 | 7 |
| 1 | 11 | 86.00 | 8 |
| 1 | 5 | 85.00 | 9 |
| 1 | 9 | 84.00 | 10 |
| 1 | 14 | 83.00 | 11 |
| 1 | 6 | 82.50 | 12 |
| 1 | 3 | 78.00 | 13 |
| 2 | 1 | 85.00 | 1 |
| 2 | 2 | 82.50 | 2 |
| 2 | 3 | 78.00 | 3 |
| 3 | 4 | 88.00 | 1 |
| 4 | 4 | 94.50 | 1 |
| 4 | 15 | 92.00 | 2 |

## DENSE_RANK()
### Рейтинг потоков по среднему баллу студентов
```postgresql
SELECT 
    flow_id,
    ROUND(AVG(current_score), 2) AS avg_score,
    DENSE_RANK() OVER (ORDER BY AVG(current_score) DESC) AS rank_by_score
FROM enrollment
WHERE current_score IS NOT NULL
GROUP BY flow_id
ORDER BY rank_by_score;
```
| flow\_id | avg\_score | rank\_by\_score |
| :--- | :--- | :--- |
| 5 | 93.25 | 1 |
| 3 | 86.58 | 2 |
| 4 | 83.38 | 3 |

## LAG()
### Разница между текущим и предыдущим средним баллом потока
```postgresql
SELECT 
    flow_id,
    ROUND(AVG(current_score), 2) AS avg_score,
    ROUND(AVG(current_score), 2) - LAG(ROUND(AVG(current_score), 2)) OVER (ORDER BY flow_id) AS diff_from_prev
FROM enrollment
WHERE current_score IS NOT NULL
GROUP BY flow_id
ORDER BY flow_id;
```
| flow\_id | avg\_score | diff\_from\_prev |
| :--- | :--- | :--- |
| 3 | 86.58 | null |
| 4 | 83.38 | -3.2 |
| 5 | 93.25 | 9.87 |

## LEAD()
### Следующая дата урока
```postgresql
SELECT 
    flow_id,
    id AS lesson_id,
    topic,
    start_at,
    LEAD(start_at) OVER (PARTITION BY flow_id ORDER BY start_at) AS next_lesson_start
FROM lesson
WHERE flow_id IS NOT NULL
ORDER BY flow_id, start_at;
```
| flow\_id | lesson\_id | topic | start\_at | next\_lesson\_start |
| :--- | :--- | :--- | :--- | :--- |
| 3 | 1 | Введение в математический анализ. Пределы | 2023-09-05 06:00:00.000000 +00:00 | 2023-09-07 06:00:00.000000 +00:00 |
| 3 | 2 | Решение задач на пределы | 2023-09-07 06:00:00.000000 +00:00 | 2023-09-12 06:00:00.000000 +00:00 |
| 3 | 3 | Производные функции | 2023-09-12 06:00:00.000000 +00:00 | null |
| 4 | 4 | Введение в C#. Основы синтаксиса | 2023-09-04 11:00:00.000000 +00:00 | 2023-09-06 11:00:00.000000 +00:00 |
| 4 | 5 | Практическая работа: Переменные и типы данных | 2023-09-06 11:00:00.000000 +00:00 | 2023-09-11 11:00:00.000000 +00:00 |
| 4 | 6 | ООП в C# | 2023-09-11 11:00:00.000000 +00:00 | 2023-09-13 11:00:00.000000 +00:00 |
| 4 | 9 | Практическая работа: Работа с БД | 2023-09-13 11:00:00.000000 +00:00 | null |
| 5 | 7 | Древняя Русь | 2023-09-05 08:00:00.000000 +00:00 | 2023-09-07 08:00:00.000000 +00:00 |
| 5 | 8 | Обсуждение эпохи Петра I | 2023-09-07 08:00:00.000000 +00:00 | null |

## FIRST_VALUE()
### Дата начала первого урока в потоке
```postgresql
SELECT
    flow_id,
    id AS lesson_id,
    start_at,
    FIRST_VALUE(start_at) OVER (PARTITION BY flow_id ORDER BY start_at) AS first_lesson_date
FROM lesson
WHERE flow_id IS NOT NULL
ORDER BY flow_id, start_at;
```
| flow\_id | lesson\_id | start\_at | first\_lesson\_date |
| :--- | :--- | :--- | :--- |
| 3 | 1 | 2023-09-05 06:00:00.000000 +00:00 | 2023-09-05 06:00:00.000000 +00:00 |
| 3 | 2 | 2023-09-07 06:00:00.000000 +00:00 | 2023-09-05 06:00:00.000000 +00:00 |
| 3 | 3 | 2023-09-12 06:00:00.000000 +00:00 | 2023-09-05 06:00:00.000000 +00:00 |
| 4 | 4 | 2023-09-04 11:00:00.000000 +00:00 | 2023-09-04 11:00:00.000000 +00:00 |
| 4 | 5 | 2023-09-06 11:00:00.000000 +00:00 | 2023-09-04 11:00:00.000000 +00:00 |
| 4 | 6 | 2023-09-11 11:00:00.000000 +00:00 | 2023-09-04 11:00:00.000000 +00:00 |
| 4 | 9 | 2023-09-13 11:00:00.000000 +00:00 | 2023-09-04 11:00:00.000000 +00:00 |
| 5 | 7 | 2023-09-05 08:00:00.000000 +00:00 | 2023-09-05 08:00:00.000000 +00:00 |
| 5 | 8 | 2023-09-07 08:00:00.000000 +00:00 | 2023-09-05 08:00:00.000000 +00:00 |

## LAST_VALUE()
### Последний студент, записавшийся в поток
```postgresql
SELECT 
    flow_id,
    user_id,
    enrolled_at,
    LAST_VALUE(user_id) OVER (
        PARTITION BY flow_id ORDER BY enrolled_at
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_student
FROM enrollment
WHERE enrolled_at IS NOT NULL
ORDER BY flow_id, enrolled_at;
```
| flow\_id | user\_id | enrolled\_at | last\_student |
| :--- | :--- | :--- | :--- |
| 3 | 1 | 2023-09-01 07:00:00.000000 +00:00 | 14 |
| 3 | 2 | 2023-09-01 07:05:00.000000 +00:00 | 14 |
| 3 | 3 | 2023-09-01 07:10:00.000000 +00:00 | 14 |
| 3 | 5 | 2023-09-01 07:15:00.000000 +00:00 | 14 |
| 3 | 6 | 2023-09-01 07:20:00.000000 +00:00 | 14 |
| 3 | 7 | 2023-09-01 07:25:00.000000 +00:00 | 14 |
| 3 | 8 | 2023-09-01 07:30:00.000000 +00:00 | 14 |
| 3 | 9 | 2023-09-01 07:35:00.000000 +00:00 | 14 |
| 3 | 10 | 2023-09-01 07:40:00.000000 +00:00 | 14 |
| 3 | 11 | 2023-09-01 07:45:00.000000 +00:00 | 14 |
| 3 | 12 | 2023-09-01 07:50:00.000000 +00:00 | 14 |
| 3 | 13 | 2023-09-01 07:55:00.000000 +00:00 | 14 |
| 3 | 14 | 2023-09-01 08:00:00.000000 +00:00 | 14 |
| 4 | 1 | 2023-09-01 08:05:00.000000 +00:00 | 4 |
| 4 | 2 | 2023-09-01 08:10:00.000000 +00:00 | 4 |
| 4 | 3 | 2023-09-01 08:15:00.000000 +00:00 | 4 |
| 4 | 4 | 2023-09-01 08:20:00.000000 +00:00 | 4 |
| 5 | 4 | 2023-09-01 09:00:00.000000 +00:00 | 15 |
| 5 | 15 | 2023-09-01 09:05:00.000000 +00:00 | 15 |
