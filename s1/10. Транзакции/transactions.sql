-- ============================================
-- ТРАНЗАКЦИИ В POSTGRESQL
-- ============================================
-- Базовые операции, уровни изоляции, SAVEPOINT
-- ============================================
-- ПРИМЕЧАНИЕ: Перед выполнением очисти тестовые данные командой:
-- DELETE FROM "user" WHERE email LIKE '%@example.com' OR email LIKE '%test%';
-- DELETE FROM enrollment WHERE status = 'enrolled' AND enrolled_at > now() - interval '1 day';

-- ============================================
-- BOOTSTRAP ДЕМО-ДАННЫХ (ИДЕМПОТЕНТНО)
-- ============================================
-- Нужен для запуска примеров в пустой БД после init_tables.sql.

INSERT INTO role (id, code, name, status)
VALUES
    (1, 'student', 'Студент', 'active'),
    (2, 'teacher', 'Преподаватель', 'active'),
    (3, 'admin', 'Администратор', 'active')
ON CONFLICT DO NOTHING;

INSERT INTO unit (id, name, type, code, status)
VALUES
    (1, 'Институт математики и информатики', 'faculty', 'IMI', 'active'),
    (2, 'Кафедра информатики', 'department', 'CS', 'active')
ON CONFLICT DO NOTHING;

INSERT INTO "user" (id, full_name, email, unit_id, status)
VALUES
    (1, 'Иванов Иван Иванович', 'ivanov@student.university.edu', 1, 'active'),
    (2, 'Петрова Мария Сергеевна', 'petrova@student.university.edu', 1, 'active'),
    (3, 'Смирнов Петр Николаевич', 'smirnov@teacher.university.edu', 2, 'active')
ON CONFLICT DO NOTHING;

INSERT INTO flow (id, code, title, unit_id, owner_id, max_students, status, start_date, end_date)
VALUES
    (1, 'MATH101-F23', 'Математический анализ, поток 2023', 1, 3, 30, 'active', DATE '2023-09-01', DATE '2024-01-31'),
    (2, 'CS201-F23', 'Программирование на C#, поток 2023', 2, 3, 30, 'active', DATE '2023-09-01', DATE '2024-01-31')
ON CONFLICT DO NOTHING;

INSERT INTO discipline (id, code, title, unit_id, flow_id, lecturer_id, status)
VALUES
    (1, 'MATH101', 'Математический анализ', 1, 1, 3, 'active'),
    (2, 'CS201', 'Программирование на C#', 2, 2, 3, 'active')
ON CONFLICT DO NOTHING;

INSERT INTO enrollment (id, user_id, discipline_id, flow_id, status, enrolled_at, current_score, attendance_pct)
VALUES
    (1, 1, 1, 1, 'active', now() - interval '1 day', 80.0, 90.0),
    (2, 2, 2, 2, 'active', now() - interval '1 day', 75.0, 85.0)
ON CONFLICT DO NOTHING;

SELECT setval(pg_get_serial_sequence('role', 'id'), COALESCE((SELECT MAX(id) FROM role), 1), true);
SELECT setval(pg_get_serial_sequence('unit', 'id'), COALESCE((SELECT MAX(id) FROM unit), 1), true);
SELECT setval(pg_get_serial_sequence('"user"', 'id'), COALESCE((SELECT MAX(id) FROM "user"), 1), true);
SELECT setval(pg_get_serial_sequence('flow', 'id'), COALESCE((SELECT MAX(id) FROM flow), 1), true);
SELECT setval(pg_get_serial_sequence('discipline', 'id'), COALESCE((SELECT MAX(id) FROM discipline), 1), true);
SELECT setval(pg_get_serial_sequence('enrollment', 'id'), COALESCE((SELECT MAX(id) FROM enrollment), 1), true);

-- ============================================
-- 1. БАЗОВЫЕ ОПЕРАЦИИ С ТРАНЗАКЦИЯМИ
-- ============================================

-- ============================================
-- 1.1. Транзакция с BEGIN ... COMMIT
-- ============================================

-- Запрос 1.1.1: Добавление пользователя и обновление связанного подразделения
-- Очищаем тестовые данные перед примером
DELETE FROM "user" WHERE email = 'sidorov@example.com';

-- Начало транзакции
BEGIN;

-- Добавляем нового пользователя
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Сидоров Сидор', 'sidorov@example.com', 1, 'active');

-- Обновляем статус связанного подразделения
UPDATE unit 
SET status = 'active', updated_at = now()
WHERE id = 1;

-- Проверяем изменения внутри транзакции
SELECT u.id, u.full_name, u.email, un.name as unit_name, un.status as unit_status
FROM "user" u
LEFT JOIN unit un ON u.unit_id = un.id
WHERE u.email = 'sidorov@example.com';

-- Подтверждаем изменения
COMMIT;

-- ============================================

-- Запрос 1.1.2: Добавление записи в enrollment и обновление связанного flow
-- Очищаем тестовые данные перед примером
DELETE FROM enrollment WHERE user_id = 1 AND flow_id = 1;

-- Начало транзакции
BEGIN;

-- Добавляем запись о зачислении
INSERT INTO enrollment (user_id, discipline_id, flow_id, status, enrolled_at)
VALUES (1, 1, 1, 'enrolled', now());

-- Обновляем количество студентов в потоке (если есть поле, иначе обновляем статус)
UPDATE flow
SET status = 'active', updated_at = now()
WHERE id = 1;

-- Проверяем результат
SELECT e.id, e.user_id, e.flow_id, e.status, f.title as flow_title
FROM enrollment e
JOIN flow f ON e.flow_id = f.id
WHERE e.id = (SELECT MAX(id) FROM enrollment);

-- Подтверждаем изменения
COMMIT;

-- ============================================
-- 1.2. Транзакция с ROLLBACK вместо COMMIT
-- ============================================

-- Запрос 1.2.1: Пробная транзакция с откатом
-- Очищаем тестовые данные перед примером
DELETE FROM "user" WHERE email = 'test-rollback@example.com';

-- Проверяем начальное состояние
SELECT COUNT(*) as user_count FROM "user" WHERE email = 'test-rollback@example.com';

-- Начало транзакции
BEGIN;

-- Добавляем тестового пользователя
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Test User', 'test-rollback@example.com', 1, 'active');

-- Обновляем подразделение
UPDATE unit 
SET updated_at = now()
WHERE id = 1;

-- Проверяем изменения внутри транзакции
SELECT u.id, u.full_name, u.email
FROM "user" u
WHERE u.email = 'test-rollback@example.com';

-- ОТКАТ транзакции
ROLLBACK;

-- Проверяем, что изменений нет
SELECT COUNT(*) as user_count_after_rollback 
FROM "user" 
WHERE email = 'test-rollback@example.com';

-- ============================================

-- Запрос 1.2.2: Откат при обновлении связанных таблиц
-- Очищаем тестовые данные перед примером
DELETE FROM enrollment WHERE user_id = 2 AND flow_id = 2;

-- Запоминаем текущее количество записей
SELECT COUNT(*) as enrollment_count_before FROM enrollment;

-- Начало транзакции
BEGIN;

-- Создаём тестовую запись зачисления
INSERT INTO enrollment (user_id, discipline_id, flow_id, status, enrolled_at)
VALUES (2, 2, 2, 'enrolled', now());

-- Обновляем поток
UPDATE flow
SET max_students = 100
WHERE id = 2;

-- Проверяем внутри транзакции
SELECT COUNT(*) as enrollment_count_inside FROM enrollment;

-- ОТКАТ
ROLLBACK;

-- Проверяем после отката
SELECT COUNT(*) as enrollment_count_after FROM enrollment;

-- ============================================
-- 1.3. Транзакция с ошибкой (деление на 0)
-- ============================================

-- Запрос 1.3.1: Ошибка в середине транзакции
-- Очищаем тестовые данные перед примером
DELETE FROM "user" WHERE email = 'error-test@example.com';

-- Проверяем начальное состояние
SELECT COUNT(*) as initial_count FROM "user" WHERE email = 'error-test@example.com';

-- Начало транзакции
BEGIN;

-- Первое изменение — успешное
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Error Test User', 'error-test@example.com', 1, 'active');

-- ОШИБКА: деление на ноль
SELECT 100 / 0;

-- Это изменение не выполнится из-за ошибки выше
UPDATE unit 
SET updated_at = now()
WHERE id = 1;

-- Попытка COMMIT (но транзакция уже в состоянии ошибки)
-- COMMIT;  -- Вызовет ошибку, так как транзакция уже в состоянии ошибки

-- Откатываем транзакцию
ROLLBACK;

-- ============================================

-- Запрос 1.3.2: Ошибка при вычислении в UPDATE
-- Очищаем тестовые данные перед примером (если запись не существует, DELETE просто ничего не удалит)
DELETE FROM enrollment WHERE user_id = 2 AND flow_id = 2;

-- Начало транзакции
BEGIN;

-- Успешное изменение (используем другие ID, чтобы избежать конфликта уникального ключа)
INSERT INTO enrollment (user_id, discipline_id, flow_id, status, enrolled_at, current_score)
VALUES (2, 2, 2, 'enrolled', now(), 85.5);

-- ОШИБКА: деление на ноль в вычислении
UPDATE enrollment
SET current_score = current_score / 0
WHERE id = (SELECT MAX(id) FROM enrollment);

-- Эта команда не выполнится
-- UPDATE flow SET updated_at = now() WHERE id = 1;

-- PostgreSQL автоматически делает ROLLBACK при ошибке
-- Проверяем состояние после ошибки
ROLLBACK;

-- ============================================
-- 2. УРОВНИ ИЗОЛЯЦИИ ТРАНЗАКЦИЙ
-- ============================================
-- Эксперименты с уровнями изоляции требуют параллельного выполнения 
-- в двух разных подключениях к базе данных для демонстрации одновременности.
-- Раскомментируй запросы T1 и T2 и выполни их параллельно в двух подключениях.
-- ============================================

-- ============================================
-- 2.1. READ COMMITTED: проверка "грязных" данных
-- ============================================

-- Запрос 2.1.1: Демонстрация READ COMMITTED
-- В PostgreSQL READ UNCOMMITTED не поддерживается (всегда минимум READ COMMITTED)
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Обновляем данные без COMMIT
UPDATE "user"
SET full_name = 'Updated Name T1'
WHERE id = 1;

-- Не делаем COMMIT, оставляем транзакцию открытой
-- (в реальном сценарии здесь мы бы не выполнили COMMIT)

-- Проверяем наши изменения
SELECT id, full_name, email 
FROM "user" 
WHERE id = 1;

-- Оставить транзакцию открытой для проверки в T2
-- COMMIT;  -- Не выполняем пока
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении, пока T1 открыта)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Пытаемся прочитать те же данные
SELECT id, full_name, email 
FROM "user" 
WHERE id = 1;

-- В PostgreSQL с уровнем READ COMMITTED транзакция T2 НЕ увидит
-- незакоммиченные изменения из T1 (нет "грязного чтения")
-- Она увидит старое значение full_name

COMMIT;
*/

-- ============================================

-- Запрос 2.1.2: UPDATE без COMMIT в T1 и чтение в T2
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Обновляем запись и не коммитим
UPDATE unit
SET name = 'Updated Unit Name T1'
WHERE id = 1;

-- Внутри T1 видим изменения
SELECT id, name, status FROM unit WHERE id = 1;

-- ОСТАВЛЯЕМ ТРАНЗАКЦИЮ ОТКРЫТОЙ (не выполняем COMMIT)
-- COMMIT;  -- Не выполняем пока
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении параллельно)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Пытаемся прочитать обновлённую строку
SELECT id, name, status FROM unit WHERE id = 1;

-- В PostgreSQL T2 НЕ увидит изменения из T1 до COMMIT
-- T2 будет ждать, если T1 заблокировала строку, или покажет старое значение

COMMIT;
*/

-- ============================================
-- 2.2. READ COMMITTED: неповторяющееся чтение
-- ============================================

-- Запрос 2.2.1: Неповторяющееся чтение
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Первое чтение
SELECT id, full_name, email, status
FROM "user"
WHERE id = 1;

-- ПАУЗА: здесь должна выполниться транзакция T2

-- Второе чтение (тот же SELECT)
SELECT id, full_name, email, status
FROM "user"
WHERE id = 1;

-- T1 увидит разные результаты в первом и втором SELECT
-- (если T2 успела сделать UPDATE и COMMIT между ними)
COMMIT;
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении между двумя SELECT в T1)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Обновляем данные, которые читала T1
UPDATE "user"
SET full_name = 'Non-repeatable Read Test', status = 'updated'
WHERE id = 1;

-- Коммитим изменения
COMMIT;

-- Теперь T1 при втором SELECT увидит новые данные
*/

-- ============================================

-- Запрос 2.2.2: Детальный пример неповторяющегося чтения
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Читаем текущий статус
SELECT id, status, updated_at 
FROM enrollment 
WHERE id = 1;

-- [ПАУЗА для выполнения T2]

-- Читаем снова - результат может измениться!
SELECT id, status, updated_at 
FROM enrollment 
WHERE id = 1;

COMMIT;
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении между чтениями в T1)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE enrollment
SET status = 'completed', updated_at = now()
WHERE id = 1;

COMMIT;
*/

-- ============================================
-- 2.3. REPEATABLE READ: защита от неповторяющегося чтения
-- ============================================

-- Запрос 2.3.1: T1 не видит изменения от T2
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Первое чтение
SELECT id, full_name, status 
FROM "user" 
WHERE id = 1;

-- [ПАУЗА: здесь T2 делает UPDATE и COMMIT]

-- Второе чтение - должно показать те же данные
SELECT id, full_name, status 
FROM "user" 
WHERE id = 1;

-- В REPEATABLE READ оба SELECT покажут одинаковый результат
-- (снимок данных на момент начала транзакции)
COMMIT;
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении во время T1)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Обновляем данные
UPDATE "user"
SET full_name = 'REPEATABLE READ Test', status = 'modified'
WHERE id = 1;

COMMIT;
*/

-- ============================================

-- Запрос 2.3.2: Фантомное чтение через INSERT в T2
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Первое чтение: считаем количество записей
SELECT COUNT(*) as user_count 
FROM "user" 
WHERE unit_id = 1;

-- [ПАУЗА: здесь T2 добавляет новую запись и делает COMMIT]

-- Второе чтение: снова считаем
SELECT COUNT(*) as user_count 
FROM "user" 
WHERE unit_id = 1;

-- В REPEATABLE READ количество должно быть одинаковым
-- (но это зависит от реализации)
COMMIT;
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении во время T1)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Добавляем новую запись
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Phantom User', 'phantom@example.com', 1, 'active');

COMMIT;
*/

-- ============================================
-- 2.4. SERIALIZABLE: предотвращение конфликтов
-- ============================================

-- Запрос 2.4.1: Конфликт при вставке одинаковых данных
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Пытаемся вставить запись с уникальным email
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Serializable User 1', 'serial-test@example.com', 1, 'active');

-- ПАУЗА: ждём выполнения T2

-- Пытаемся закоммитить
COMMIT;
-- Если возникает конфликт, получим ошибку serialization
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении параллельно с T1)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Т2 тоже пытается вставить запись с тем же email
-- (если уникальный constraint на email)
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Serializable User 2', 'serial-test@example.com', 1, 'active');

-- Пытаемся закоммитить
COMMIT;

-- Одна из транзакций получит ошибку:
-- "could not serialize access due to read/write dependencies among transactions"
*/

-- ============================================

-- Запрос 2.4.2: Поимка ошибки serialization и повтор транзакции
--

-- ТРАНЗАКЦИЯ T1 (выполнить в первом подключении)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Обновляем запись на основе текущего значения
UPDATE enrollment
SET current_score = current_score + 10, updated_at = now()
WHERE id = 1;

-- Пытаемся закоммитить
COMMIT;
-- Если возникла ошибка serialization:
-- ERROR: could not serialize access due to concurrent update
*/

-- ТРАНЗАКЦИЯ T2 (выполнить во втором подключении параллельно)
/*
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- T2 тоже обновляет ту же запись
UPDATE enrollment
SET current_score = current_score + 15, updated_at = now()
WHERE id = 1;

COMMIT;
-- Одна из транзакций получит ошибку serialization
*/

-- Пример обработки ошибки serialization (в приложении или скрипте)
-- ВАЖНО: Этот пример демонстрирует логику, но требует выполнения в отдельной транзакции
-- В реальном приложении это должно выполняться через клиентский код с обработкой ошибок

-- Вариант 1: Простая транзакция с обработкой ошибок (для демонстрации)
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Попытка обновления
UPDATE enrollment
SET current_score = current_score + 10, updated_at = now()
WHERE id = 1;

-- Если ошибки нет - коммитим
COMMIT;

-- Если возникает ошибка serialization, выполни:
-- ROLLBACK;
-- И повтори транзакцию заново

-- ============================================
-- 3. SAVEPOINT: точки сохранения в транзакции
-- ============================================

-- ============================================
-- 3.1. Транзакция с несколькими изменениями и точкой сохранения
-- ============================================

-- Запрос 3.1.1: SAVEPOINT с частичным откатом
-- Очищаем тестовые данные перед примером
DELETE FROM "user" WHERE email IN ('savepoint1@example.com', 'savepoint2@example.com');

-- Начало транзакции
BEGIN;

-- Первое изменение
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Savepoint User 1', 'savepoint1@example.com', 1, 'active');

-- Проверяем
SELECT COUNT(*) as count_after_insert1 
FROM "user" 
WHERE email = 'savepoint1@example.com';

-- Создаём точку сохранения
SAVEPOINT sp1;

-- Второе изменение
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Savepoint User 2', 'savepoint2@example.com', 1, 'active');

-- Третье изменение
UPDATE unit
SET updated_at = now()
WHERE id = 1;

-- Проверяем все изменения
SELECT COUNT(*) as count_before_rollback 
FROM "user" 
WHERE email IN ('savepoint1@example.com', 'savepoint2@example.com');

-- Откатываемся к точке сохранения sp1
ROLLBACK TO SAVEPOINT sp1;

-- Проверяем после отката
SELECT COUNT(*) as count_after_rollback_to_sp1 
FROM "user" 
WHERE email IN ('savepoint1@example.com', 'savepoint2@example.com');

-- Изменения до SAVEPOINT остались, после SAVEPOINT - откатились
-- Закоммитим оставшиеся изменения
COMMIT;

-- Финальная проверка
SELECT COUNT(*) as final_count 
FROM "user" 
WHERE email IN ('savepoint1@example.com', 'savepoint2@example.com');

-- ============================================

-- Запрос 3.1.2: SAVEPOINT с сохранением изменений
-- Очищаем тестовые данные перед примером
DELETE FROM enrollment WHERE user_id = 3 AND flow_id = 1;

BEGIN;

-- Первая операция (используем другие ID, чтобы избежать конфликта уникального ключа)
INSERT INTO enrollment (user_id, discipline_id, flow_id, status, enrolled_at)
VALUES (3, 1, 1, 'enrolled', now());

-- Создаём точку сохранения
SAVEPOINT before_update;

-- Обновляем запись (используем конкретный ID из только что созданной записи)
UPDATE enrollment
SET current_score = 90.0
WHERE user_id = 3 AND flow_id = 1;

-- Проверяем изменения внутри транзакции
SELECT id, user_id, status, current_score 
FROM enrollment 
WHERE user_id = 3 AND flow_id = 1;

-- Подтверждаем все изменения (до и после SAVEPOINT)
COMMIT;

-- Проверяем результат
SELECT id, user_id, status, current_score 
FROM enrollment 
WHERE user_id = 3 AND flow_id = 1;

-- ============================================
-- 3.2. Два SAVEPOINT и возврат на первый и второй
-- ============================================

-- Запрос 3.2.1: Множественные SAVEPOINT с откатом
-- Очищаем тестовые данные перед примером
DELETE FROM "user" WHERE email IN ('multisp1@example.com', 'multisp2@example.com');

BEGIN;

-- Изменение 1: добавляем пользователя
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Multi Savepoint User 1', 'multisp1@example.com', 1, 'active');

-- Первая точка сохранения
SAVEPOINT sp1;

-- Изменение 2: добавляем второго пользователя
INSERT INTO "user" (full_name, email, unit_id, status)
VALUES ('Multi Savepoint User 2', 'multisp2@example.com', 1, 'active');

-- Вторая точка сохранения
SAVEPOINT sp2;

-- Изменение 3: обновляем подразделение
UPDATE unit
SET name = 'Updated Unit Name'
WHERE id = 1;

-- Проверяем текущее состояние
SELECT COUNT(*) as all_changes 
FROM "user" 
WHERE email IN ('multisp1@example.com', 'multisp2@example.com');

-- Откатываемся к sp2 (откатываем только изменение 3)
ROLLBACK TO SAVEPOINT sp2;

-- Проверяем после отката к sp2
SELECT COUNT(*) as after_rollback_to_sp2 
FROM "user" 
WHERE email IN ('multisp1@example.com', 'multisp2@example.com');

-- Откатываемся к sp1 (откатываем изменения 2 и 3)
ROLLBACK TO SAVEPOINT sp1;

-- Проверяем после отката к sp1
SELECT COUNT(*) as after_rollback_to_sp1 
FROM "user" 
WHERE email IN ('multisp1@example.com', 'multisp2@example.com');

-- Закоммитим оставшиеся изменения (только изменение 1)
COMMIT;

-- Финальная проверка
SELECT COUNT(*) as final_count 
FROM "user" 
WHERE email IN ('multisp1@example.com', 'multisp2@example.com');

-- ============================================

-- Запрос 3.2.2: Возврат на разные SAVEPOINT
-- Очищаем тестовые данные перед примером
DELETE FROM enrollment WHERE user_id = 2 AND flow_id = 2;

BEGIN;

-- Изменение 1
INSERT INTO enrollment (user_id, discipline_id, flow_id, status, enrolled_at, current_score)
VALUES (2, 2, 2, 'enrolled', now(), 75.0);

-- Первый SAVEPOINT
SAVEPOINT checkpoint1;

-- Изменение 2
UPDATE enrollment
SET current_score = 80.0
WHERE id = (SELECT MAX(id) FROM enrollment);

-- Второй SAVEPOINT
SAVEPOINT checkpoint2;

-- Изменение 3
UPDATE enrollment
SET current_score = 85.0
WHERE id = (SELECT MAX(id) FROM enrollment);

-- Проверяем текущий балл
SELECT id, current_score FROM enrollment WHERE id = (SELECT MAX(id) FROM enrollment);

-- Возвращаемся на checkpoint2 (откатываем изменение 3)
ROLLBACK TO SAVEPOINT checkpoint2;

-- Проверяем балл после отката к checkpoint2
SELECT id, current_score FROM enrollment WHERE id = (SELECT MAX(id) FROM enrollment);

-- Возвращаемся на checkpoint1 (откатываем изменения 2 и 3)
ROLLBACK TO SAVEPOINT checkpoint1;

-- Проверяем балл после отката к checkpoint1
SELECT id, current_score FROM enrollment WHERE id = (SELECT MAX(id) FROM enrollment);

-- Закоммитим оставшиеся изменения
COMMIT;
