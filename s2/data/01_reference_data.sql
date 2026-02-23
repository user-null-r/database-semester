BEGIN;

TRUNCATE TABLE
    lecturer_phone,
    exam_classroom,
    lesson_classroom,
    discipline_teacher,
    user_role,
    enrollment,
    exam,
    assignment,
    assignment_status,
    exam_status,
    lesson,
    classroom,
    discipline,
    flow,
    "user",
    unit,
    role
RESTART IDENTITY CASCADE;

INSERT INTO exam_status (name) VALUES
('planned'),
('ongoing'),
('completed'),
('cancelled');

INSERT INTO assignment_status (name) VALUES
('draft'),
('published'),
('submitted'),
('graded'),
('archived');

INSERT INTO role (code, name, description, is_system, status) VALUES
('student', 'Student', 'Student role', TRUE, 'active'),
('teacher', 'Teacher', 'Teacher role', TRUE, 'active'),
('manager', 'Manager', 'Department manager', TRUE, 'active'),
('methodist', 'Methodist', 'Methodical support', TRUE, 'active'),
('assistant', 'Assistant', 'Teaching assistant', TRUE, 'active');

INSERT INTO unit (name, type, code, parent_id, email, phone, status)
SELECT
    'Unit ' || gs,
    CASE
        WHEN gs <= 10 THEN 'faculty'
        WHEN gs <= 40 THEN 'department'
        ELSE 'program'
    END,
    'U' || lpad(gs::text, 3, '0'),
    NULL,
    'unit' || lpad(gs::text, 3, '0') || '@deanery.local',
    '+7-900-100-' || lpad(gs::text, 4, '0'),
    CASE WHEN gs % 20 = 0 THEN 'inactive' ELSE 'active' END
FROM generate_series(1, 100) AS gs;

UPDATE unit
SET parent_id = ((id - 1) / 10) + 1
WHERE id > 10;

INSERT INTO classroom (
    building,
    room_number,
    campus,
    capacity,
    floor,
    has_projector,
    has_pc,
    is_accessible,
    status
)
SELECT
    'Building ' || (((gs - 1) % 12) + 1),
    (100 + gs)::text,
    CASE WHEN gs % 2 = 0 THEN 'North' ELSE 'South' END,
    20 + ((gs - 1) % 180),
    1 + ((gs - 1) % 9),
    gs % 5 <> 0,
    gs % 3 <> 0,
    gs % 8 <> 0,
    CASE WHEN gs % 30 = 0 THEN 'maintenance' ELSE 'active' END
FROM generate_series(1, 500) AS gs;

COMMIT;
