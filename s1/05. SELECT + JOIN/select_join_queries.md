## 1) SELECT + CASE (2 запроса)
  
### 1.1 Студенты, потоки и уровень посещаемости (CASE по `attendance_pct`)

```sql

SELECT

u.id,

u.full_name,

f.code AS flow_code,

e.attendance_pct,

CASE

WHEN e.attendance_pct >= 90 THEN 'высокая'

WHEN e.attendance_pct >= 70 THEN 'средняя'

WHEN e.attendance_pct IS NULL THEN 'нет данных'

ELSE 'низкая'

END AS attendance_level

FROM enrollment e

JOIN "user" u ON u.id = e.user_id

JOIN flow f ON f.id = e.flow_id

ORDER BY u.full_name, f.code;

```

РЕЗУЛЬТАТ — <img width="700" height="157" alt="image" src="https://github.com/user-attachments/assets/b7b14db5-5123-4304-8d87-c468f96935b2" />


  

### 1.2 Экзамены и «временной статус» (CASE по времени и `status`)

```sql

SELECT

ex.id,

ex.type,

ex.scheduled_start,

ex.scheduled_end,

ex.status,

CASE

WHEN ex.status = 'canceled' THEN 'отменён'

WHEN now() < ex.scheduled_start THEN 'запланирован'

WHEN now() BETWEEN ex.scheduled_start AND ex.scheduled_end THEN 'идёт сейчас'

WHEN now() > ex.scheduled_end THEN 'завершён'

ELSE 'неизвестно'

END AS time_state

FROM exam ex

ORDER BY ex.scheduled_start NULLS LAST;

```

РЕЗУЛЬТАТ — <img width="770" height="122" alt="image" src="https://github.com/user-attachments/assets/bae6b9f6-c825-4dd5-bfab-14ee2b60b5be" />


---

  

## 2) JOIN (по 2 запроса на каждый вид)

  

### 2.1 INNER JOIN — вариант A: «студент → поток → дисциплина» через `enrollment`

```sql

SELECT

u.full_name AS student,

d.code AS discipline_code,

d.title AS discipline_title,

f.code AS flow_code

FROM enrollment e

JOIN "user" u ON u.id = e.user_id

JOIN flow f ON f.id = e.flow_id

JOIN discipline d ON d.id = e.discipline_id

ORDER BY u.full_name, d.code;

```

РЕЗУЛЬТАТ — <img width="727" height="153" alt="image" src="https://github.com/user-attachments/assets/5ffbce90-7d2d-473b-8ea6-9bf9d3d19c67" />


### 2.2 INNER JOIN — вариант B: задания по потокам (есть только где есть задания)

```sql

SELECT

f.code AS flow_code,

f.title AS flow_title,

COUNT(a.id) AS assignments_count

FROM flow f

JOIN assignment a ON a.flow_id = f.id

GROUP BY f.id, f.code, f.title

ORDER BY assignments_count DESC, f.code;

```

РЕЗУЛЬТАТ — <img width="530" height="98" alt="image" src="https://github.com/user-attachments/assets/693a24a8-0c0f-46c1-8e59-16b995082848" />
  

### 2.3 LEFT JOIN — вариант A: все пользователи с их ролью

```sql

SELECT

u.id,

u.full_name,

r.code AS role_code,

r.name AS role_name

FROM "user" u

LEFT JOIN role r ON r.id = u.role_id

ORDER BY u.full_name;

```

РЕЗУЛЬТАТ — <img width="618" height="262" alt="image" src="https://github.com/user-attachments/assets/94cba864-8ad6-474e-9971-f685177ab012" />


### 2.4 LEFT JOIN — вариант B: все потоки и количество студентов (0 допускается)

```sql

SELECT

f.id,

f.code,

f.title,

COALESCE(COUNT(e.user_id), 0) AS students_count

FROM flow f

LEFT JOIN enrollment e ON e.flow_id = f.id

GROUP BY f.id, f.code, f.title

ORDER BY students_count DESC, f.code;

```

РЕЗУЛЬТАТ — <img width="600" height="164" alt="image" src="https://github.com/user-attachments/assets/5af20dc3-32b9-4e7d-b9a7-c7bf91d2100f" />


### 2.5 RIGHT JOIN — вариант A: показать все потоки, даже без студентов

```sql

SELECT

f.code AS flow_code,

COALESCE(COUNT(e.user_id), 0) AS students_count

FROM enrollment e

RIGHT JOIN flow f ON f.id = e.flow_id

GROUP BY f.id, f.code

ORDER BY f.code;

```

РЕЗУЛЬТАТ — <img width="348" height="160" alt="image" src="https://github.com/user-attachments/assets/191cd246-5860-42ef-b285-18b002b3cafd" />


### 2.6 RIGHT JOIN — вариант B: показать все роли, даже если ни одному пользователю не назначено

```sql

SELECT

r.code AS role_code,

r.name AS role_name,

COUNT(u.id) AS users_with_role

FROM "user" u

RIGHT JOIN role r ON r.id = u.role_id

GROUP BY r.id, r.code, r.name

ORDER BY r.code;

```

РЕЗУЛЬТАТ — <img width="509" height="135" alt="image" src="https://github.com/user-attachments/assets/0ee6dd77-22be-404e-8a52-af9c48826304" />


### 2.7 CROSS JOIN — вариант A: декартово произведение «роль × статус пользователя»

```sql

SELECT

r.code AS role_code,

r.name AS role_name,

s.status

FROM role r

CROSS JOIN (

SELECT DISTINCT status FROM "user"

) AS s

ORDER BY r.code, s.status;

```

РЕЗУЛЬТАТ — <img width="549" height="124" alt="image" src="https://github.com/user-attachments/assets/043be849-cdb8-48df-9adb-6edcf2b015e4" />


### 2.8 CROSS JOIN — вариант B: «типы занятий × дни недели» (полезно для отчёта-шаблона)

```sql

WITH lesson_types AS (

SELECT unnest(ARRAY['lecture','seminar','lab']) AS ltype

),

dow AS (

SELECT unnest(ARRAY['Mon','Tue','Wed','Thu','Fri','Sat','Sun']) AS day_short

)

SELECT lt.ltype, d.day_short

FROM lesson_types lt

CROSS JOIN dow d

ORDER BY lt.ltype, d.day_short;

```

РЕЗУЛЬТАТ — <img width="207" height="625" alt="image" src="https://github.com/user-attachments/assets/ab414f93-bf11-49cb-8edf-79325cbe50d7" />


### 2.9 FULL OUTER JOIN — вариант A: аудитории и факты использования занятиями

```sql

SELECT

c.id AS classroom_id,

c.building,

c.room_number,

l.id AS lesson_id,

l.start_at

FROM classroom c

FULL OUTER JOIN lesson l ON l.auditorium_id = c.id

ORDER BY c.building NULLS FIRST, c.room_number NULLS FIRST, l.start_at NULLS LAST;

```

РЕЗУЛЬТАТ — <img width="770" height="130" alt="image" src="https://github.com/user-attachments/assets/907f4543-177c-41f0-90e8-2e0e2f6bd67f" />


### 2.10 FULL OUTER JOIN — вариант B: экзамены и прокторы (покажем всё с обеих сторон)

```sql

SELECT

ex.id AS exam_id,

ex.type,

ex.scheduled_start,

ex.scheduled_end,

p.full_name AS proctor_name

FROM exam ex

FULL OUTER JOIN "user" p ON p.id = ex.proctor_id

ORDER BY ex.scheduled_start NULLS LAST, proctor_name NULLS LAST;

```

РЕЗУЛЬТАТ — <img width="765" height="295" alt="image" src="https://github.com/user-attachments/assets/7b94a4a3-33eb-4a6f-a23d-bb3607e5095b" />
