# Агрегатные функции

## AVG

### Среднее количество зачетных единиц по каждому потоку
Считаем среднее значение зачетных единиц для всех потоков.
```pgsql
SELECT AVG(credits) AS avg_flow_credits
FROM flow
WHERE credits IS NOT NULL;
```

### Средний максимальный балл заданий по дисциплине
Считаем средний максимальный балл всех заданий в каждой дисциплине.
```pgsql
SELECT discipline_id, AVG(max_score) AS avg_assignment_score
FROM assignment
GROUP BY discipline_id;
```

## COUNT

### Количество пользователей в каждом подразделении
Считаем, сколько пользователей относится к каждому подразделению (unit).
```pgsql
SELECT unit_id, COUNT(*) AS user_count
FROM "user"
GROUP BY unit_id;
```

### Количество зачислений по каждому потоку
Считаем, сколько студентов зачислено в каждый поток.
```pgsql
SELECT flow_id, COUNT(*) AS total_enrollments
FROM enrollment
GROUP BY flow_id;
```

## MIN и MAX

### Ранние и поздние даты начала и окончания потоков
Находим самую раннюю дату начала и самую позднюю дату окончания среди всех потоков.
```pgsql
SELECT MIN(start_date) AS first_flow_start,
       MAX(end_date) AS last_flow_end
FROM flow;
```

### Самые ранние и поздние даты сдачи заданий по дисциплине
Находим минимальную и максимальную даты сдачи заданий для каждой дисциплины.
```pgsql
SELECT discipline_id,
       MIN(due_at) AS earliest_due,
       MAX(due_at) AS latest_due
FROM assignment
GROUP BY discipline_id;
```

## SUM

### Общая вместимость всех аудиторий
Суммируем вместимость всех аудиторий.
```pgsql
SELECT SUM(capacity) AS total_classroom_capacity
FROM classroom;
```

### Общая сумма доступных баллов по дисциплине
Суммируем максимальные баллы всех заданий по каждой дисциплине.
```pgsql
SELECT discipline_id,
       SUM(COALESCE(max_score, 0)) AS total_available_points
FROM assignment
GROUP BY discipline_id;
```

## STRING_AGG

### Объединяем коды всех ролей через запятую
Формируем строку с кодами всех ролей, разделённых запятой.
```pgsql
SELECT STRING_AGG(code, ', ') AS all_roles
FROM role;
```

### Список пользователей по подразделению, разделённых новой строкой
Формируем строку с полными именами пользователей, разделённых переносом строки.
```pgsql
SELECT unit_id,
       STRING_AGG(full_name, E'\n') AS members
FROM "user"
GROUP BY unit_id;
```

# HAVING

### Потоки с более чем 50 зачисленными студентами
Находим потоки, где количество зачисленных студентов превышает 50.
```pgsql
SELECT f.id AS flow_id,
       f.title AS flow_title,
       COUNT(e.id) AS total_enrollments
FROM flow f
JOIN enrollment e ON f.id = e.flow_id
GROUP BY f.id, f.title
HAVING COUNT(e.id) > 50;
```

### Преподаватели, ведущие более 3 дисциплин
Находим преподавателей, которые назначены более чем на три дисциплины.
```pgsql
SELECT u.id AS teacher_id,
       u.full_name AS teacher_name,
       COUNT(dt.discipline_id) AS total_disciplines
FROM "user" u
JOIN discipline_teacher dt ON u.id = dt.teacher_id
GROUP BY u.id, u.full_name
HAVING COUNT(dt.discipline_id) > 3;
```

# GROUPING SETS

### Количество зачислений по потоку и по дисциплине
Считаем количество зачислений по каждому потоку и каждой дисциплине, включая общий итог.
```pgsql
SELECT f.title AS flow_title,
       d.title AS discipline_title,
       COUNT(e.id) AS enrollment_count
FROM enrollment e
LEFT JOIN flow f ON e.flow_id = f.id
LEFT JOIN discipline d ON e.discipline_id = d.id
GROUP BY GROUPING SETS ((f.title), (d.title), ());
```

### Количество заданий по типу и по статусу
Считаем количество заданий по каждому типу и по статусу, включая общий итог.
```pgsql
SELECT type, status, COUNT(*) AS assignment_count
FROM assignment
GROUP BY GROUPING SETS ((type), (status), ());
```

### Средний максимальный балл заданий по типу и по статусу
Считаем средний максимальный балл по каждому типу и статусу заданий, включая общий итог.
```pgsql
SELECT type,
       status,
       AVG(max_score) AS avg_max_score
FROM assignment
GROUP BY GROUPING SETS ((type), (status), ());
```

# ROLLUP

### Количество пользователей по подразделению и статусу
Считаем пользователей по подразделению и по статусу, включая промежуточные и общие итоги.
```pgsql
SELECT u.name AS unit_name,
       usr.status,
       COUNT(*) AS user_count
FROM "user" usr
LEFT JOIN unit u ON usr.unit_id = u.id
GROUP BY ROLLUP (u.name, usr.status);
```

### Сумма зачетных единиц по подразделению и потоку
Считаем сумму зачетных единиц по подразделению и потоку с промежуточными и общими итогами.
```pgsql
SELECT u.name AS unit_name,
       f.title AS flow_title,
       SUM(f.credits) AS total_credits
FROM flow f
LEFT JOIN unit u ON f.unit_id = u.id
GROUP BY ROLLUP (u.name, f.title);
```

# CUBE

### Наличие аудиторий по зданию и статусу
Считаем количество аудиторий по каждому зданию и статусу, включая все комбинации.
```pgsql
SELECT building,
       status,
       COUNT(*) AS room_count
FROM classroom
GROUP BY CUBE (building, status);
```

### Средняя успеваемость студентов по потоку и дисциплине
Считаем средний текущий балл студентов по каждому потоку и дисциплине, включая все комбинации.
```pgsql
SELECT
    f.title AS flow_title,
    d.title AS discipline_title,
    AVG(e.current_score) AS avg_student_score
FROM enrollment e
LEFT JOIN flow f ON e.flow_id = f.id
LEFT JOIN discipline d ON e.discipline_id = d.id
GROUP BY CUBE (f.title, d.title);
```
