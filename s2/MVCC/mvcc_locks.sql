-- Блоки T1/T2 нужно выполнять в двух разных сессиях.

-- ПОДГОТОВКА

CREATE EXTENSION IF NOT EXISTS pageinspect;

DROP SCHEMA IF EXISTS hw_mvcc CASCADE;
CREATE SCHEMA hw_mvcc;

CREATE TABLE hw_mvcc.demo (
    id integer PRIMARY KEY,
    payload text,
    note text
);

INSERT INTO hw_mvcc.demo VALUES (1, 'v1', 'init');

CREATE TABLE hw_mvcc.lock_demo (
    id integer PRIMARY KEY,
    payload text
);

INSERT INTO hw_mvcc.lock_demo VALUES
    (1, 'row-1'),
    (2, 'row-2');

-- 1. xmin, xmax, ctid

SELECT ctid, xmin, xmax, * FROM hw_mvcc.demo;

UPDATE hw_mvcc.demo
SET payload = 'v2',
    note = 'after update'
WHERE id = 1;

SELECT ctid, xmin, xmax, * FROM hw_mvcc.demo;

-- 2. t_infomask и физические версии строки

SELECT h.lp,
       h.t_xmin,
       h.t_xmax,
       h.t_ctid,
       h.t_infomask,
       h.t_infomask2,
       f.raw_flags,
       f.combined_flags
FROM heap_page_items(get_raw_page('hw_mvcc.demo', 0)) AS h
CROSS JOIN LATERAL heap_tuple_infomask_flags(h.t_infomask, h.t_infomask2) AS f
ORDER BY h.lp;


-- 3. Те же поля в разных транзакциях. Выполнять в двух сессиях: T1 и T2

-- T1
BEGIN;
UPDATE hw_mvcc.demo
SET payload = 'v3_uncommitted',
     note = 'updated but not committed'
 WHERE id = 1;
SELECT txid_current() AS t1_xid, ctid, xmin, xmax, id, payload, note
FROM hw_mvcc.demo
WHERE id = 1;
-- не коммитить, пока не выполнен запрос T2
COMMIT;

-- T2
SELECT txid_current() AS t2_xid, ctid, xmin, xmax, id, payload, note
FROM hw_mvcc.demo
WHERE id = 1;
SELECT h.lp,
h.t_xmin,
h.t_xmax,
h.t_ctid,
h.t_infomask,
h.t_infomask2,
f.raw_flags,
f.combined_flags
FROM heap_page_items(get_raw_page('hw_mvcc.demo', 0)) AS h
CROSS JOIN LATERAL heap_tuple_infomask_flags(h.t_infomask, h.t_infomask2) AS f
ORDER BY h.lp;

-- Наблюдение блокировок, пока одна из транзакций ждет другую

SELECT pid,
locktype,
mode,
granted,
relation::regclass,
page,
tuple,
transactionid,
pg_blocking_pids(pid) AS blocked_by
FROM pg_locks
WHERE relation = 'hw_mvcc.lock_demo'::regclass
OR locktype = 'transactionid'
ORDER BY pid, locktype, mode;

-- Row-level locks - примеры конфликтов
-- Выполнять в двух сессиях

-- FOR UPDATE vs FOR SHARE -> конфликт

-- T1
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR UPDATE;

-- T2
SET lock_timeout = '700ms';
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR SHARE;
ROLLBACK;

-- FOR NO KEY UPDATE и FOR KEY SHARE -> совместимо

-- T1
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR NO KEY UPDATE;

-- T2
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR KEY SHARE;
ROLLBACK;

-- FOR SHARE vs FOR SHARE -> совместимо

-- T1
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR SHARE;

-- T2
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR SHARE;
ROLLBACK;

-- FOR KEY SHARE и FOR UPDATE -> конфликт

-- T1
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR KEY SHARE;

-- T2
SET lock_timeout = '700ms';
BEGIN;
SELECT * FROM hw_mvcc.lock_demo WHERE id = 1 FOR UPDATE;
ROLLBACK;

-- После каждого:
ROLLBACK;

-- Дедлок (выполнять в двух сессиях)

-- T1
BEGIN;
SET deadlock_timeout = '200ms';
-- шаг 1
UPDATE hw_mvcc.lock_demo SET payload = 'row-1-t1' WHERE id = 1;
-- шаг 3
UPDATE hw_mvcc.lock_demo SET payload = 'row-2-t1' WHERE id = 2;
COMMIT;

-- T2
BEGIN;
SET deadlock_timeout = '200ms';
-- шаг 2
UPDATE hw_mvcc.lock_demo SET payload = 'row-2-t2' WHERE id = 2;
-- шаг 4
UPDATE hw_mvcc.lock_demo SET payload = 'row-1-t2' WHERE id = 1;
ROLLBACK;

-- Очистка данных
DROP SCHEMA IF EXISTS hw_mvcc CASCADE;
