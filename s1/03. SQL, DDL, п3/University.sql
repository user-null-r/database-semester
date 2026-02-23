-- ============================================
-- ФАЙЛ СОЗДАНИЯ БАЗОВОЙ СТРУКТУРЫ БД
-- ============================================
-- ВНИМАНИЕ: Это исходная структура БД до нормализации
-- Для создания полной нормализованной БД используйте init_correct.sql
-- 
-- Этот файл предназначен для обучения и показывает исходную структуру
-- Все команды безопасны для выполнения в pgAdmin

-- СОЗДАНИЕ ТАБЛИЦ
CREATE TABLE role (
                      id BIGSERIAL PRIMARY KEY,
                      code VARCHAR(50) UNIQUE NOT NULL,
                      name VARCHAR(100) NOT NULL,
                      description TEXT,
                      is_system BOOLEAN DEFAULT FALSE,
                      status VARCHAR(20) NOT NULL,
                      created_at TIMESTAMPTZ DEFAULT now(),
                      updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE unit (
                      id BIGSERIAL PRIMARY KEY,
                      name VARCHAR(255) NOT NULL,
                      type VARCHAR(50) NOT NULL,
                      code VARCHAR(50),
                      parent_id BIGINT REFERENCES unit(id),
                      email VARCHAR(255),
                      phone VARCHAR(20),
                      status VARCHAR(20) NOT NULL,
                      created_at TIMESTAMPTZ DEFAULT now(),
                      updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE "user" (
                        id BIGSERIAL PRIMARY KEY,
                        full_name VARCHAR(255) NOT NULL,
                        email VARCHAR(255) UNIQUE NOT NULL,
                        phone VARCHAR(20),
                        role_id BIGINT REFERENCES role(id),
                        unit_id BIGINT REFERENCES unit(id),
                        student_number VARCHAR(50),
                        employee_position VARCHAR(100),
                        status VARCHAR(20) NOT NULL,
                        created_at TIMESTAMPTZ DEFAULT now(),
                        updated_at TIMESTAMPTZ DEFAULT now(),
                        last_login_at TIMESTAMPTZ
);

CREATE TABLE discipline (
                            id BIGSERIAL PRIMARY KEY,
                            code VARCHAR(50) UNIQUE NOT NULL,
                            title VARCHAR(255) NOT NULL,
                            description TEXT,
                            ects_credits NUMERIC(4,1),
                            hours_total INT,
                            unit_id BIGINT REFERENCES unit(id),
                            level VARCHAR(20),
                            language VARCHAR(50),
                            status VARCHAR(20) NOT NULL,
                            created_at TIMESTAMPTZ DEFAULT now(),
                            updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE flow (
                      id BIGSERIAL PRIMARY KEY,
                      code VARCHAR(50) UNIQUE NOT NULL,
                      title VARCHAR(255) NOT NULL,
                      unit_id BIGINT REFERENCES unit(id),
                      owner_id BIGINT REFERENCES "user"(id),
                      credits NUMERIC(4,1),
                      cohort_year INT,
                      modality VARCHAR(20),
                      language VARCHAR(50),
                      start_date DATE,
                      end_date DATE,
                      add_drop_deadline DATE,
                      exam_window_start DATE,
                      exam_window_end DATE,
                      grade_submit_deadline DATE,
                      max_students INT,
                      status VARCHAR(20) NOT NULL,
                      created_at TIMESTAMPTZ DEFAULT now(),
                      updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE classroom (
                           id BIGSERIAL PRIMARY KEY,
                           building VARCHAR(100),
                           room_number VARCHAR(20),
                           campus VARCHAR(100),
                           capacity INT,
                           floor INT,
                           has_projector BOOLEAN,
                           has_pc BOOLEAN,
                           is_accessible BOOLEAN,
                           status VARCHAR(20),
                           created_at TIMESTAMPTZ DEFAULT now(),
                           updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE session (
                         id BIGSERIAL PRIMARY KEY,
                         flow_id BIGINT REFERENCES flow(id),
                         auditorium_id BIGINT REFERENCES classroom(id),
                         type VARCHAR(20),
                         topic VARCHAR(255),
                         start_at TIMESTAMPTZ,
                         end_at TIMESTAMPTZ,
                         teacher_id BIGINT REFERENCES "user"(id),
                         online_link VARCHAR(255),
                         attendance_required BOOLEAN,
                         status VARCHAR(20),
                         created_at TIMESTAMPTZ DEFAULT now(),
                         updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE assignment (
                            id BIGSERIAL PRIMARY KEY,
                            flow_id BIGINT REFERENCES flow(id),
                            title VARCHAR(255),
                            type VARCHAR(20),
                            description TEXT,
                            release_at TIMESTAMPTZ,
                            due_at TIMESTAMPTZ,
                            late_policy VARCHAR(20),
                            submission_type VARCHAR(20),
                            allow_multiple BOOLEAN,
                            max_attempts INT,
                            max_score NUMERIC(5,2),
                            visibility VARCHAR(20),
                            status VARCHAR(20),
                            created_at TIMESTAMPTZ DEFAULT now(),
                            updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE enrollment (
                            id BIGSERIAL PRIMARY KEY,
                            user_id BIGINT REFERENCES "user"(id),
                            discipline_id BIGINT REFERENCES discipline(id),
                            flow_id BIGINT REFERENCES flow(id),
                            role VARCHAR(20),
                            enrolled_at TIMESTAMPTZ,
                            dropped_at TIMESTAMPTZ,
                            attendance_pct NUMERIC(5,2),
                            current_score NUMERIC(6,2),
                            final_grade VARCHAR(5),
                            status VARCHAR(20),
                            created_at TIMESTAMPTZ DEFAULT now(),
                            updated_at TIMESTAMPTZ DEFAULT now(),
                            UNIQUE(user_id, flow_id)
);

CREATE TABLE exam (
                      id BIGSERIAL PRIMARY KEY,
                      flow_id BIGINT REFERENCES flow(id),
                      type VARCHAR(20),
                      scheduled_start TIMESTAMPTZ,
                      scheduled_end TIMESTAMPTZ,
                      auditorium_id BIGINT REFERENCES classroom(id),
                      format VARCHAR(20),
                      duration_min INT,
                      max_score NUMERIC(5,2),
                      proctor_id BIGINT REFERENCES "user"(id),
                      status VARCHAR(20),
                      created_at TIMESTAMPTZ DEFAULT now(),
                      updated_at TIMESTAMPTZ DEFAULT now()
);

-- ALTER-ЗАПРОСЫ

ALTER TABLE "user" ADD middle_name VARCHAR(100);

ALTER TABLE "user" ALTER COLUMN phone TYPE VARCHAR(30);

ALTER TABLE discipline DROP COLUMN hours_total;

ALTER TABLE classroom ADD CONSTRAINT uq_classroom UNIQUE(building, room_number);

ALTER TABLE session RENAME TO lesson;

-- INSERT ТЕСТОВЫЕ ДАННЫЕ

INSERT INTO role (code, name, status) VALUES
                                          ('student', 'Студент', 'active'),
                                          ('teacher', 'Преподаватель', 'active');

INSERT INTO unit (name, type, code, status) VALUES
                                                ('Институт математики', 'faculty', 'MATH', 'active'),
                                                ('Кафедра информатики', 'department', 'CS', 'active');

INSERT INTO "user" (full_name, email, role_id, unit_id, status) VALUES
                                                                    ('Иванов Иван', 'ivanov@example.com', 1, 1, 'active'),
                                                                    ('Петров Пётр', 'petrov@example.com', 2, 2, 'active');

INSERT INTO discipline (code, title, ects_credits, unit_id, level, language, status) VALUES
                                                                                         ('MATH101', 'Математический анализ', 6.0, 1, 'bachelor', 'ru', 'active'),
                                                                                         ('CS201', 'Программирование на C#', 4.0, 2, 'bachelor', 'ru', 'active');

INSERT INTO flow (code, title, unit_id, owner_id, credits, cohort_year, status) VALUES
                                                                                    ('MATH101-F23', 'Матанализ, поток 2023', 1, 2, 6.0, 2023, 'active'),
                                                                                    ('CS201-F23', 'C#, поток 2023', 2, 2, 4.0, 2023, 'active');

INSERT INTO exam (flow_id, type, scheduled_start, scheduled_end, format, duration_min, max_score, status) VALUES
                                                                                                              (1, 'final', '2025-06-10 09:00+03', '2025-06-10 12:00+03', 'written', 180, 100, 'planned'),
                                                                                                              (2, 'midterm', '2025-05-01 10:00+03', '2025-05-01 11:30+03', 'test', 90, 50, 'planned');

-- UPDATE ЗАПРОСЫ

UPDATE "user" SET email = 'ivanov.new@example.com' WHERE full_name = 'Иванов Иван';

UPDATE discipline SET unit_id = 1 WHERE code = 'CS201';

UPDATE exam SET scheduled_start = '2025-06-15 09:00+03', scheduled_end = '2025-06-15 12:00+03' WHERE id = 1;

UPDATE flow SET status = 'completed' WHERE code = 'MATH101-F23';

UPDATE enrollment SET attendance_pct = 95.00 WHERE id = 1;