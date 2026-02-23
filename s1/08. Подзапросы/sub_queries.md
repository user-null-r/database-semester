# Подзапросы

## 1. Подзапросы в SELECT (3 запроса)

### 1.1 Список пользователей с количеством их зачислений
```sql
SELECT 
    u.id,
    u.full_name,
    (SELECT COUNT(*) 
     FROM enrollment e 
     WHERE e.user_id = u.id) AS enrollments_count
FROM "user" u
ORDER BY enrollments_count DESC, u.full_name;
```

### 1.2 Потоки с количеством студентов и средним баллом
```sql
SELECT 
    f.id,
    f.code,
    f.title,
    (SELECT COUNT(*) 
     FROM enrollment e 
     WHERE e.flow_id = f.id) AS students_count,
    (SELECT AVG(e.current_score) 
     FROM enrollment e 
     WHERE e.flow_id = f.id 
     AND e.current_score IS NOT NULL) AS avg_score
FROM flow f
ORDER BY f.code;
```

### 1.3 Дисциплины с количеством заданий и экзаменов
```sql
SELECT 
    d.id,
    d.code,
    d.title,
    (SELECT COUNT(*) 
     FROM assignment a 
     WHERE a.discipline_id = d.id) AS assignments_count,
    (SELECT COUNT(*) 
     FROM exam ex 
     WHERE ex.discipline_id = d.id) AS exams_count
FROM discipline d
ORDER BY d.code;
```

---

## 2. Подзапросы в FROM (3 запроса)

### 2.1 Топ-5 студентов с наибольшим количеством зачислений
```sql
SELECT 
    u.full_name,
    sub.enrollments_count
FROM "user" u
JOIN (
    SELECT 
        user_id,
        COUNT(*) AS enrollments_count
    FROM enrollment
    GROUP BY user_id
) AS sub ON u.id = sub.user_id
ORDER BY sub.enrollments_count DESC
LIMIT 5;
```

### 2.2 Дисциплины с количеством преподавателей и средним ECTS
```sql
SELECT 
    d.code,
    d.title,
    sub.teachers_count,
    d.ects_credits
FROM discipline d
JOIN (
    SELECT 
        discipline_id,
        COUNT(*) AS teachers_count
    FROM discipline_teacher
    GROUP BY discipline_id
) AS sub ON d.id = sub.discipline_id
WHERE d.ects_credits > (
    SELECT AVG(ects_credits) 
    FROM discipline 
    WHERE ects_credits IS NOT NULL
)
ORDER BY sub.teachers_count DESC, d.code;
```

### 2.3 Потоки с информацией о загруженности аудиторий
```sql
SELECT 
    f.code AS flow_code,
    f.title AS flow_title,
    sub.lessons_count,
    sub.classrooms_used
FROM flow f
JOIN (
    SELECT 
        l.flow_id,
        COUNT(DISTINCT l.id) AS lessons_count,
        COUNT(DISTINCT lc.classroom_id) AS classrooms_used
    FROM lesson l
    LEFT JOIN lesson_classroom lc ON l.id = lc.lesson_id
    GROUP BY l.flow_id
) AS sub ON f.id = sub.flow_id
ORDER BY sub.lessons_count DESC;
```

---

## 3. Подзапросы в WHERE (3 запроса)

### 3.1 Пользователи, зачисленные в потоки с более чем 10 студентами
```sql
SELECT 
    u.id,
    u.full_name,
    f.code AS flow_code
FROM "user" u
JOIN enrollment e ON u.id = e.user_id
JOIN flow f ON e.flow_id = f.id
WHERE f.id IN (
    SELECT flow_id
    FROM enrollment
    GROUP BY flow_id
    HAVING COUNT(*) > 10
)
ORDER BY u.full_name, f.code;
```

### 3.2 Дисциплины, у которых есть задания с максимальным баллом больше 50
```sql
SELECT 
    d.id,
    d.code,
    d.title
FROM discipline d
WHERE d.id IN (
    SELECT DISTINCT discipline_id
    FROM assignment
    WHERE max_score > 50
)
ORDER BY d.code;
```

### 3.3 Аудитории, которые не используются ни в одном занятии
```sql
SELECT 
    c.id,
    c.building,
    c.room_number,
    c.capacity
FROM classroom c
WHERE c.id NOT IN (
    SELECT DISTINCT classroom_id
    FROM lesson_classroom
    WHERE classroom_id IS NOT NULL
)
ORDER BY c.building, c.room_number;
```

---

## 4. Подзапросы в HAVING (3 запроса)

### 4.1 Потоки, где средняя посещаемость больше средней по всем потокам
```sql
SELECT 
    f.id,
    f.code,
    f.title,
    AVG(e.attendance_pct) AS avg_attendance
FROM flow f
JOIN enrollment e ON f.id = e.flow_id
WHERE e.attendance_pct IS NOT NULL
GROUP BY f.id, f.code, f.title
HAVING AVG(e.attendance_pct) > (
    SELECT AVG(attendance_pct)
    FROM enrollment
    WHERE attendance_pct IS NOT NULL
)
ORDER BY avg_attendance DESC;
```

### 4.2 Подразделения с количеством пользователей больше среднего
```sql
SELECT 
    u.id,
    u.name,
    COUNT(usr.id) AS users_count
FROM unit u
LEFT JOIN "user" usr ON u.id = usr.unit_id
GROUP BY u.id, u.name
HAVING COUNT(usr.id) > (
    SELECT AVG(user_count)
    FROM (
        SELECT unit_id, COUNT(*) AS user_count
        FROM "user"
        WHERE unit_id IS NOT NULL
        GROUP BY unit_id
    ) AS sub
)
ORDER BY users_count DESC;
```

### 4.3 Дисциплины с количеством заданий больше среднего
```sql
SELECT 
    d.id,
    d.code,
    d.title,
    COUNT(a.id) AS assignments_count
FROM discipline d
LEFT JOIN assignment a ON d.id = a.discipline_id
GROUP BY d.id, d.code, d.title
HAVING COUNT(a.id) > (
    SELECT AVG(assignment_count)
    FROM (
        SELECT discipline_id, COUNT(*) AS assignment_count
        FROM assignment
        WHERE discipline_id IS NOT NULL
        GROUP BY discipline_id
    ) AS sub
)
ORDER BY assignments_count DESC;
```

---

## 5. Подзапросы с ALL (3 запроса)

### 5.1 Студенты с максимальным текущим баллом в своём потоке
```sql
SELECT 
    u.full_name,
    f.code AS flow_code,
    e.current_score
FROM "user" u
JOIN enrollment e ON u.id = e.user_id
JOIN flow f ON e.flow_id = f.id
WHERE e.current_score >= ALL (
    SELECT current_score
    FROM enrollment e2
    WHERE e2.flow_id = e.flow_id
    AND e2.current_score IS NOT NULL
)
AND e.current_score IS NOT NULL
ORDER BY e.current_score DESC, f.code;
```

### 5.2 Задания с максимальным баллом в своей дисциплине
```sql
SELECT 
    a.id,
    a.title,
    d.code AS discipline_code,
    a.max_score
FROM assignment a
JOIN discipline d ON a.discipline_id = d.id
WHERE a.max_score >= ALL (
    SELECT max_score
    FROM assignment a2
    WHERE a2.discipline_id = a.discipline_id
    AND a2.max_score IS NOT NULL
)
AND a.max_score IS NOT NULL
ORDER BY a.max_score DESC, d.code;
```

### 5.3 Потоки с самым ранним дедлайном добавления/удаления
```sql
SELECT 
    f.id,
    f.code,
    f.title,
    f.add_drop_deadline
FROM flow f
WHERE f.add_drop_deadline <= ALL (
    SELECT add_drop_deadline
    FROM flow f2
    WHERE f2.add_drop_deadline IS NOT NULL
)
AND f.add_drop_deadline IS NOT NULL
ORDER BY f.add_drop_deadline;
```

---

## 6. Подзапросы с IN (3 запроса)

### 6.1 Пользователи, зачисленные в активные потоки
```sql
SELECT 
    u.id,
    u.full_name,
    u.email
FROM "user" u
WHERE u.id IN (
    SELECT DISTINCT user_id
    FROM enrollment e
    JOIN flow f ON e.flow_id = f.id
    WHERE f.status = 'active'
)
ORDER BY u.full_name;
```

### 6.2 Дисциплины, у которых есть экзамены в будущем (после текущей даты)
```sql
SELECT 
    d.id,
    d.code,
    d.title
FROM discipline d
WHERE d.id IN (
    SELECT DISTINCT discipline_id
    FROM exam
    WHERE scheduled_start > CURRENT_DATE
    AND discipline_id IS NOT NULL
)
ORDER BY d.code;
```

### 6.3 Аудитории, используемые в экзаменах
```sql
SELECT 
    c.id,
    c.building,
    c.room_number,
    c.capacity
FROM classroom c
WHERE c.id IN (
    SELECT DISTINCT classroom_id
    FROM exam_classroom
    WHERE classroom_id IS NOT NULL
)
ORDER BY c.building, c.room_number;
```

---

## 7. Подзапросы с ANY (3 запроса)

### 7.1 Пользователи, имеющие хотя бы одно зачисление с посещаемостью выше 80%
```sql
SELECT 
    u.id,
    u.full_name,
    e.attendance_pct
FROM "user" u
JOIN enrollment e ON u.id = e.user_id
WHERE e.attendance_pct > ANY (
    SELECT 80.0
)
AND e.attendance_pct IS NOT NULL
ORDER BY e.attendance_pct DESC, u.full_name;
```

### 7.2 Задания с максимальным баллом больше любого из заданий определённого типа
```sql
SELECT 
    a.id,
    a.title,
    a.type,
    a.max_score
FROM assignment a
WHERE a.max_score > ANY (
    SELECT max_score
    FROM assignment a2
    WHERE a2.type = 'homework'
    AND a2.max_score IS NOT NULL
)
AND a.max_score IS NOT NULL
ORDER BY a.max_score DESC;
```

### 7.3 Потоки, которые начались раньше любого потока определённого подразделения
```sql
SELECT 
    f.id,
    f.code,
    f.title,
    f.start_date
FROM flow f
WHERE f.start_date < ANY (
    SELECT start_date
    FROM flow f2
    WHERE f2.unit_id = (SELECT id FROM unit WHERE code = 'IGH')
    AND f2.start_date IS NOT NULL
)
AND f.start_date IS NOT NULL
ORDER BY f.start_date;
```

---

## 8. Подзапросы с EXISTS (3 запроса)

### 8.1 Дисциплины, у которых есть хотя бы одно задание
```sql
SELECT 
    d.id,
    d.code,
    d.title
FROM discipline d
WHERE EXISTS (
    SELECT 1
    FROM assignment a
    WHERE a.discipline_id = d.id
)
ORDER BY d.code;
```

### 8.2 Пользователи, которые не зачислены ни в один поток
```sql
SELECT 
    u.id,
    u.full_name,
    u.email
FROM "user" u
WHERE NOT EXISTS (
    SELECT 1
    FROM enrollment e
    WHERE e.user_id = u.id
)
ORDER BY u.full_name;
```

### 8.3 Аудитории, которые используются в занятиях, но не в экзаменах
```sql
SELECT 
    c.id,
    c.building,
    c.room_number
FROM classroom c
WHERE EXISTS (
    SELECT 1
    FROM lesson_classroom lc
    WHERE lc.classroom_id = c.id
)
AND NOT EXISTS (
    SELECT 1
    FROM exam_classroom ec
    WHERE ec.classroom_id = c.id
)
ORDER BY c.building, c.room_number;
```

---

## 9. Сравнение по нескольким столбцам (3 запроса)

### 9.1 Найти пользователей с такой же комбинацией роли и подразделения, как у определённого пользователя
```sql
SELECT 
    u1.id,
    u1.full_name,
    u1.email,
    ur1.role_id,
    u1.unit_id
FROM "user" u1
JOIN user_role ur1 ON u1.id = ur1.user_id
WHERE (ur1.role_id, u1.unit_id) IN (
    SELECT ur2.role_id, u2.unit_id
    FROM "user" u2
    JOIN user_role ur2 ON u2.id = ur2.user_id
    WHERE u2.email = 'ivanov@student.university.edu'
)
AND u1.email != 'ivanov@student.university.edu'
ORDER BY u1.full_name;
```

### 9.2 Найти потоки с такой же комбинацией дат начала и окончания
```sql
SELECT 
    f1.id,
    f1.code,
    f1.title,
    f1.start_date,
    f1.end_date
FROM flow f1
WHERE (f1.start_date, f1.end_date) IN (
    SELECT f2.start_date, f2.end_date
    FROM flow f2
    WHERE f2.start_date IS NOT NULL
    AND f2.end_date IS NOT NULL
    GROUP BY f2.start_date, f2.end_date
    HAVING COUNT(*) > 1
)
ORDER BY f1.start_date, f1.code;
```

### 9.3 Найти занятия с такой же комбинацией типа и даты начала
```sql
SELECT 
    l1.id,
    l1.flow_id,
    l1.type,
    l1.start_at,
    l1.end_at
FROM lesson l1
WHERE (l1.type, l1.start_at::DATE) IN (
    SELECT 
        l2.type,
        l2.start_at::DATE
    FROM lesson l2
    WHERE l2.type IS NOT NULL
    AND l2.start_at IS NOT NULL
    GROUP BY l2.type, l2.start_at::DATE
    HAVING COUNT(*) > 1
)
ORDER BY l1.start_at;
```

---

## 10. Коррелированные подзапросы (5 запросов)

### 10.1 Для каждого пользователя найти количество его зачислений
```sql
SELECT 
    u.id,
    u.full_name,
    (
        SELECT COUNT(*)
        FROM enrollment e
        WHERE e.user_id = u.id
    ) AS enrollments_count
FROM "user" u
ORDER BY enrollments_count DESC, u.full_name;
```

### 10.2 Для каждой дисциплины найти средний балл заданий
```sql
SELECT 
    d.id,
    d.code,
    d.title,
    (
        SELECT AVG(a.max_score)
        FROM assignment a
        WHERE a.discipline_id = d.id
        AND a.max_score IS NOT NULL
    ) AS avg_assignment_score
FROM discipline d
ORDER BY avg_assignment_score DESC NULLS LAST, d.code;
```

### 10.3 Для каждого потока найти студента с максимальным баллом
```sql
SELECT 
    f.id,
    f.code,
    f.title,
    (
        SELECT u.full_name
        FROM enrollment e
        JOIN "user" u ON e.user_id = u.id
        WHERE e.flow_id = f.id
        AND e.current_score IS NOT NULL
        ORDER BY e.current_score DESC
        LIMIT 1
    ) AS top_student,
    (
        SELECT MAX(e.current_score)
        FROM enrollment e
        WHERE e.flow_id = f.id
        AND e.current_score IS NOT NULL
    ) AS max_score
FROM flow f
WHERE EXISTS (
    SELECT 1
    FROM enrollment e2
    WHERE e2.flow_id = f.id
    AND e2.current_score IS NOT NULL
)
ORDER BY f.code;
```

### 10.4 Для каждого подразделения найти количество пользователей и дисциплин
```sql
SELECT 
    u.id,
    u.name,
    u.type,
    (
        SELECT COUNT(*)
        FROM "user" usr
        WHERE usr.unit_id = u.id
    ) AS users_count,
    (
        SELECT COUNT(*)
        FROM discipline d
        WHERE d.flow_id IN (
            SELECT f.id
            FROM flow f
            WHERE f.unit_id = u.id
        )
    ) AS disciplines_count
FROM unit u
ORDER BY u.name;
```

### 10.5 Для каждого занятия найти количество используемых аудиторий
```sql
SELECT 
    l.id,
    l.flow_id,
    l.type,
    l.start_at,
    (
        SELECT COUNT(*)
        FROM lesson_classroom lc
        WHERE lc.lesson_id = l.id
    ) AS classrooms_count
FROM lesson l
ORDER BY l.start_at NULLS LAST;
```
