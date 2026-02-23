CREATE TABLE IF NOT EXISTS role (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS unit (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    code VARCHAR(50) UNIQUE,
    parent_id BIGINT REFERENCES unit(id),
    email VARCHAR(255),
    phone VARCHAR(20),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "user" (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30),
    role_id BIGINT REFERENCES role(id),
    unit_id BIGINT REFERENCES unit(id),
    student_number VARCHAR(50),
    employee_position VARCHAR(100),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_login_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS flow (
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

CREATE TABLE IF NOT EXISTS discipline (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    ects_credits NUMERIC(4,1),
    unit_id BIGINT REFERENCES unit(id),
    flow_id BIGINT REFERENCES flow(id),
    lecturer_id BIGINT REFERENCES "user"(id),
    level VARCHAR(20),
    language VARCHAR(50),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS classroom (
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
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT uq_classroom UNIQUE(building, room_number)
);

CREATE TABLE IF NOT EXISTS lesson (
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

CREATE TABLE IF NOT EXISTS exam_status (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS assignment_status (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS assignment (
    id BIGSERIAL PRIMARY KEY,
    flow_id BIGINT REFERENCES flow(id),
    discipline_id BIGINT REFERENCES discipline(id),
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
    status_id INT REFERENCES assignment_status(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS enrollment (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES "user"(id),
    discipline_id BIGINT REFERENCES discipline(id),
    flow_id BIGINT REFERENCES flow(id),
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

CREATE TABLE IF NOT EXISTS exam (
    id BIGSERIAL PRIMARY KEY,
    flow_id BIGINT REFERENCES flow(id),
    discipline_id BIGINT REFERENCES discipline(id),
    type VARCHAR(20),
    scheduled_start TIMESTAMPTZ,
    scheduled_end TIMESTAMPTZ,
    auditorium_id BIGINT REFERENCES classroom(id),
    format VARCHAR(20),
    duration_min INT,
    max_score NUMERIC(5,2),
    proctor_id BIGINT REFERENCES "user"(id),
    status VARCHAR(20),
    status_id INT REFERENCES exam_status(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_role (
    user_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS discipline_teacher (
    discipline_id BIGINT NOT NULL REFERENCES discipline(id) ON DELETE CASCADE,
    teacher_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    PRIMARY KEY (discipline_id, teacher_id)
);

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

CREATE TABLE IF NOT EXISTS lecturer_phone (
    lecturer_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    PRIMARY KEY (lecturer_id, phone_number)
);
