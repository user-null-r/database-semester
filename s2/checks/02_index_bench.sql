-- Таблица: user
-- Колонка: student_number

-- 1) БЕЗ ИНДЕКСА

DROP INDEX IF EXISTS idx_user_student_number_btree;
DROP INDEX IF EXISTS idx_user_student_number_hash;
ANALYZE "user";

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number > 'STU-200000';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number < 'STU-050000';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number = 'STU-120010';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number LIKE '%1200%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number LIKE 'STU-1200%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number IN (
    'STU-000010',
    'STU-050010',
    'STU-100010',
    'STU-150010',
    'STU-200010'
);

-- 2) B-TREE

DROP INDEX IF EXISTS idx_user_student_number_hash;
DROP INDEX IF EXISTS idx_user_student_number_btree;
CREATE INDEX idx_user_student_number_btree
    ON "user" USING btree (student_number);
ANALYZE "user";

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number > 'STU-200000';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number < 'STU-050000';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number = 'STU-120010';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number LIKE '%1200%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number LIKE 'STU-1200%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number IN (
    'STU-000010',
    'STU-050010',
    'STU-100010',
    'STU-150010',
    'STU-200010'
);

-- 3) HASH

DROP INDEX IF EXISTS idx_user_student_number_btree;
DROP INDEX IF EXISTS idx_user_student_number_hash;
CREATE INDEX idx_user_student_number_hash
    ON "user" USING hash (student_number);
ANALYZE "user";

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number > 'STU-200000';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number < 'STU-050000';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number = 'STU-120010';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number LIKE '%1200%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number LIKE 'STU-1200%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_number
FROM "user"
WHERE student_number IN (
    'STU-000010',
    'STU-050010',
    'STU-100010',
    'STU-150010',
    'STU-200010'
);

-- Очистка:
-- DROP INDEX IF EXISTS idx_user_student_number_btree;
-- DROP INDEX IF EXISTS idx_user_student_number_hash;
