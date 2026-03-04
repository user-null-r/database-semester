SELECT u.id,
       u.full_name,
       r.name AS role_name,
       un.name AS unit_name
FROM "user" u
JOIN role r ON r.id = u.role_id
LEFT JOIN unit un ON un.id = u.unit_id
WHERE u.status = 'active'
ORDER BY u.id
LIMIT 10;

SELECT f.id,
       f.code,
       f.title,
       owner.full_name AS owner_name,
       un.name AS unit_name
FROM flow f
JOIN "user" owner ON owner.id = f.owner_id
JOIN unit un ON un.id = f.unit_id
WHERE f.status = 'active'
ORDER BY f.id
LIMIT 10;

SELECT e.id,
       u.full_name,
       f.code AS flow_code,
       d.code AS discipline_code,
       e.attendance_pct,
       e.current_score
FROM enrollment e
JOIN "user" u ON u.id = e.user_id
JOIN flow f ON f.id = e.flow_id
JOIN discipline d ON d.id = e.discipline_id
WHERE e.status = 'active'
ORDER BY e.id
LIMIT 10;

SELECT a.id,
       a.title,
       a.type,
       d.title AS discipline_title,
       f.code AS flow_code,
       a.status
FROM assignment a
JOIN discipline d ON d.id = a.discipline_id
JOIN flow f ON f.id = a.flow_id
WHERE a.status IN ('published', 'submitted')
ORDER BY a.id
LIMIT 10;

SELECT ex.id,
       ex.type,
       ex.format,
       cr.building,
       cr.room_number,
       p.full_name AS proctor_name,
       ex.status
FROM exam ex
LEFT JOIN classroom cr ON cr.id = ex.auditorium_id
LEFT JOIN "user" p ON p.id = ex.proctor_id
ORDER BY ex.id
LIMIT 10;
