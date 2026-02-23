-- Normalization compatibility script for the canonical schema.
-- This script is intentionally non-destructive and idempotent.
-- Expected order: init_tables.sql -> normalform.sql

DO $$
BEGIN
    IF to_regclass('public.role') IS NULL
       OR to_regclass('public.unit') IS NULL
       OR to_regclass('public."user"') IS NULL
       OR to_regclass('public.flow') IS NULL
       OR to_regclass('public.discipline') IS NULL
       OR to_regclass('public.classroom') IS NULL
       OR to_regclass('public.lesson') IS NULL
       OR to_regclass('public.assignment') IS NULL
       OR to_regclass('public.enrollment') IS NULL
       OR to_regclass('public.exam') IS NULL THEN
        RAISE EXCEPTION 'Run init_tables.sql before normalform.sql';
    END IF;
END $$;

-- 1NF helper tables
CREATE TABLE IF NOT EXISTS lesson_classroom (
    lesson_id BIGINT NOT NULL REFERENCES lesson(id) ON DELETE CASCADE,
    classroom_id BIGINT NOT NULL REFERENCES classroom(id) ON DELETE CASCADE,
    PRIMARY KEY (lesson_id, classroom_id)
);

CREATE TABLE IF NOT EXISTS exam_classroom (
    exam_id BIGINT NOT NULL REFERENCES exam(id) ON DELETE CASCADE,
    classroom_id BIGINT NOT NULL REFERENCES classroom(id) ON DELETE CASCADE,
    PRIMARY KEY (exam_id, classroom_id)
);

CREATE TABLE IF NOT EXISTS user_role (
    user_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS lecturer_phone (
    lecturer_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    PRIMARY KEY (lecturer_id, phone_number)
);

-- 3NF helper tables
CREATE TABLE IF NOT EXISTS discipline_teacher (
    discipline_id BIGINT NOT NULL REFERENCES discipline(id) ON DELETE CASCADE,
    teacher_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    PRIMARY KEY (discipline_id, teacher_id)
);

CREATE TABLE IF NOT EXISTS exam_status (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS assignment_status (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- Compatibility columns used by different homeworks
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS middle_name VARCHAR(100);
ALTER TABLE "user" ADD COLUMN IF NOT EXISTS role_id BIGINT REFERENCES role(id);
ALTER TABLE classroom ADD COLUMN IF NOT EXISTS campus VARCHAR(100);

ALTER TABLE lesson ADD COLUMN IF NOT EXISTS auditorium_id BIGINT REFERENCES classroom(id);

ALTER TABLE discipline ADD COLUMN IF NOT EXISTS flow_id BIGINT REFERENCES flow(id);
ALTER TABLE discipline ADD COLUMN IF NOT EXISTS lecturer_id BIGINT REFERENCES "user"(id);

ALTER TABLE assignment ADD COLUMN IF NOT EXISTS discipline_id BIGINT REFERENCES discipline(id);
ALTER TABLE assignment ADD COLUMN IF NOT EXISTS status_id INT REFERENCES assignment_status(id) ON DELETE SET NULL;

ALTER TABLE exam ADD COLUMN IF NOT EXISTS discipline_id BIGINT REFERENCES discipline(id);
ALTER TABLE exam ADD COLUMN IF NOT EXISTS status_id INT REFERENCES exam_status(id) ON DELETE SET NULL;
