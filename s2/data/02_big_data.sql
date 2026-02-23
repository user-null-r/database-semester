INSERT INTO "user" (
    full_name,
    middle_name,
    email,
    phone,
    role_id,
    unit_id,
    student_number,
    employee_position,
    status,
    created_at,
    updated_at,
    last_login_at,
    about_text,
    profile,
    interests,
    home_point,
    preferred_study_slot
)
SELECT
    'User ' || gs,
    CASE WHEN gs % 10 = 0 THEN NULL ELSE 'M' || (gs % 7000) END,
    'user' || lpad(gs::text, 6, '0') || '@deanery.local',
    CASE WHEN gs % 8 = 0 THEN NULL ELSE '+7-930-' || lpad((gs % 10000000)::text, 7, '0') END,
    CASE
        WHEN gs % 100 < 60 THEN 1
        WHEN gs % 100 < 80 THEN 2
        WHEN gs % 100 < 90 THEN 3
        WHEN gs % 100 < 97 THEN 4
        ELSE 5
    END,
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 10) + 1
        ELSE ((gs - 1) % 100) + 1
    END,
    CASE WHEN gs % 100 < 80 THEN 'STU-' || lpad(gs::text, 6, '0') ELSE NULL END,
    CASE
        WHEN gs % 100 < 15 THEN NULL
        WHEN gs % 100 < 75 THEN 'student'
        WHEN gs % 100 < 90 THEN 'teacher'
        ELSE 'manager'
    END,
    CASE
        WHEN gs % 100 < 90 THEN 'active'
        WHEN gs % 100 < 97 THEN 'on_leave'
        ELSE 'blocked'
    END,
    now() - (gs % 1825) * interval '1 day',
    now() - (gs % 365) * interval '1 day',
    CASE WHEN gs % 100 < 20 THEN NULL ELSE now() - (gs % 120) * interval '1 day' END,
    CASE
        WHEN gs % 100 < 12 THEN NULL
        ELSE 'Студент ' || gs || ' изучает SQL и аналитику.'
    END,
    CASE
        WHEN gs % 100 < 8 THEN NULL
        ELSE jsonb_build_object(
            'gpa', round((2 + random() * 3)::numeric, 2),
            'mode', CASE WHEN gs % 2 = 0 THEN 'offline' ELSE 'online' END
        )
    END,
    CASE
        WHEN gs % 100 < 10 THEN NULL
        ELSE ARRAY[
            'interest_' || (gs % 40),
            'topic_' || (gs % 120),
            'group_' || (gs % 15)
        ]::text[]
    END,
    CASE WHEN gs % 100 < 9 THEN NULL ELSE point(37.2 + random() * 0.8, 55.5 + random() * 0.8) END,
    CASE
        WHEN gs % 100 < 15 THEN NULL
        ELSE tstzrange(
            now() - (gs % 120) * interval '1 day',
            now() + ((gs % 60) + 1) * interval '1 day',
            '[)'
        )
    END
FROM generate_series(1, 250000) AS gs;

INSERT INTO flow (
    code,
    title,
    unit_id,
    owner_id,
    credits,
    cohort_year,
    modality,
    language,
    start_date,
    end_date,
    add_drop_deadline,
    exam_window_start,
    exam_window_end,
    grade_submit_deadline,
    max_students,
    status,
    created_at,
    updated_at,
    summary_text,
    metadata,
    tags,
    campus_point,
    active_period
)
SELECT
    'FLOW-' || lpad(gs::text, 6, '0'),
    'Flow ' || gs,
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 10) + 1
        ELSE ((gs - 1) % 100) + 1
    END,
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 25000) + 1
        ELSE ((gs - 1) % 250000) + 1
    END,
    (2 + (gs % 16) * 0.5)::numeric(4,1),
    2019 + (gs % 8),
    CASE gs % 4
        WHEN 0 THEN 'fulltime'
        WHEN 1 THEN 'parttime'
        WHEN 2 THEN 'hybrid'
        ELSE 'distance'
    END,
    CASE gs % 4
        WHEN 0 THEN 'ru'
        WHEN 1 THEN 'en'
        WHEN 2 THEN 'de'
        ELSE 'es'
    END,
    date '2019-01-01' + (gs % 2400),
    date '2019-01-01' + (gs % 2400) + (90 + (gs % 120)),
    date '2019-01-01' + (gs % 2400) + 14,
    date '2019-01-01' + (gs % 2400) + (70 + (gs % 90)),
    date '2019-01-01' + (gs % 2400) + (71 + (gs % 90)),
    date '2019-01-01' + (gs % 2400) + (95 + (gs % 120)),
    40 + (gs % 260),
    CASE
        WHEN gs % 100 < 65 THEN 'active'
        WHEN gs % 100 < 85 THEN 'planned'
        WHEN gs % 100 < 95 THEN 'completed'
        ELSE 'archived'
    END,
    now() - (gs % 1825) * interval '1 day',
    now() - (gs % 800) * interval '1 day',
    CASE WHEN gs % 100 < 10 THEN NULL ELSE 'Поток ' || gs || ': практика SQL и аналитики.' END,
    CASE
        WHEN gs % 100 < 8 THEN NULL
        ELSE jsonb_build_object(
            'difficulty', 1 + (gs % 5),
            'priority', CASE WHEN gs % 100 < 70 THEN 'core' ELSE 'elective' END
        )
    END,
    CASE
        WHEN gs % 100 < 10 THEN NULL
        ELSE ARRAY['track_' || (gs % 50), 'semester_' || (gs % 8), 'region_' || (gs % 12)]::text[]
    END,
    CASE WHEN gs % 100 < 8 THEN NULL ELSE point(37.2 + random() * 0.8, 55.5 + random() * 0.8) END,
    CASE
        WHEN gs % 100 < 6 THEN NULL
        ELSE daterange(
            date '2019-01-01' + (gs % 2400),
            date '2019-01-01' + (gs % 2400) + (90 + (gs % 120)),
            '[)'
        )
    END
FROM generate_series(1, 250000) AS gs;

INSERT INTO discipline (
    code,
    title,
    description,
    ects_credits,
    unit_id,
    flow_id,
    lecturer_id,
    level,
    language,
    status,
    created_at,
    updated_at
)
SELECT
    'DISC-' || lpad(gs::text, 5, '0'),
    'Discipline ' || gs,
    CASE WHEN gs % 100 < 10 THEN NULL ELSE 'Курс ' || gs || ' по моделированию данных и аналитике.' END,
    (2 + (gs % 10) * 0.5)::numeric(4,1),
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 10) + 1
        ELSE ((gs - 1) % 100) + 1
    END,
    ((gs - 1) % 250000) + 1,
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 25000) + 1
        ELSE ((gs - 1) % 250000) + 1
    END,
    CASE gs % 4
        WHEN 0 THEN 'bachelor'
        WHEN 1 THEN 'master'
        WHEN 2 THEN 'specialist'
        ELSE 'phd'
    END,
    CASE gs % 4
        WHEN 0 THEN 'ru'
        WHEN 1 THEN 'en'
        WHEN 2 THEN 'de'
        ELSE 'es'
    END,
    CASE WHEN gs % 100 < 85 THEN 'active' ELSE 'archived' END,
    now() - (gs % 1825) * interval '1 day',
    now() - (gs % 900) * interval '1 day'
FROM generate_series(1, 50000) AS gs;

INSERT INTO assignment (
    flow_id,
    discipline_id,
    title,
    type,
    description,
    release_at,
    due_at,
    late_policy,
    submission_type,
    allow_multiple,
    max_attempts,
    max_score,
    visibility,
    status,
    status_id,
    created_at,
    updated_at
)
SELECT
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 25000) + 1
        ELSE ((gs - 1) % 250000) + 1
    END,
    ((gs - 1) % 50000) + 1,
    'Assignment ' || gs,
    CASE gs % 5
        WHEN 0 THEN 'lab'
        WHEN 1 THEN 'project'
        WHEN 2 THEN 'quiz'
        WHEN 3 THEN 'essay'
        ELSE 'exam-prep'
    END,
    CASE WHEN gs % 100 < 12 THEN NULL ELSE 'Задание ' || gs || ': SQL-анализ и отчёт.' END,
    timestamp with time zone '2024-01-01 00:00:00+03' + (gs % 730) * interval '1 day',
    timestamp with time zone '2024-01-01 00:00:00+03' + (gs % 730) * interval '1 day' + ((gs % 14) + 3) * interval '1 day',
    CASE gs % 4
        WHEN 0 THEN 'none'
        WHEN 1 THEN 'soft'
        WHEN 2 THEN 'hard'
        ELSE 'with_penalty'
    END,
    CASE gs % 3
        WHEN 0 THEN 'file'
        WHEN 1 THEN 'text'
        ELSE 'repo_link'
    END,
    gs % 2 = 0,
    1 + (gs % 4),
    CASE WHEN gs % 100 < 50 THEN 100.00 ELSE 50.00 END,
    CASE gs % 3
        WHEN 0 THEN 'public'
        WHEN 1 THEN 'course_only'
        ELSE 'private'
    END,
    CASE
        WHEN gs % 100 < 15 THEN 'draft'
        WHEN gs % 100 < 70 THEN 'published'
        WHEN gs % 100 < 90 THEN 'submitted'
        ELSE 'graded'
    END,
    (gs % 5) + 1,
    timestamp with time zone '2024-01-01 00:00:00+03' + (gs % 730) * interval '1 day',
    timestamp with time zone '2024-01-01 00:00:00+03' + (gs % 730) * interval '1 day' + (gs % 30) * interval '1 day'
FROM generate_series(1, 250000) AS gs;

INSERT INTO enrollment (
    user_id,
    discipline_id,
    flow_id,
    enrolled_at,
    dropped_at,
    attendance_pct,
    current_score,
    final_grade,
    status,
    created_at,
    updated_at
)
SELECT
    gs,
    (
        (
            CASE
                WHEN gs % 100 < 70 THEN ((gs - 1) % 25000) + 1
                ELSE ((gs - 1) % 250000) + 1
            END - 1
        ) % 50000
    ) + 1,
    CASE
        WHEN gs % 100 < 70 THEN ((gs - 1) % 25000) + 1
        ELSE ((gs - 1) % 250000) + 1
    END,
    timestamp with time zone '2023-09-01 00:00:00+03' + (gs % 900) * interval '1 day',
    CASE
        WHEN gs % 100 >= 90 THEN
            timestamp with time zone '2023-09-01 00:00:00+03'
            + (gs % 900) * interval '1 day'
            + ((gs % 120) + 1) * interval '1 day'
        ELSE NULL
    END,
    CASE WHEN gs % 100 < 8 THEN NULL ELSE round((55 + random() * 45)::numeric, 2) END,
    CASE WHEN gs % 100 < 12 THEN NULL ELSE round((35 + random() * 65)::numeric, 2) END,
    CASE
        WHEN gs % 100 < 15 THEN NULL
        ELSE (ARRAY['A', 'B', 'C', 'D', 'E'])[(gs % 5) + 1]
    END,
    CASE
        WHEN gs % 100 < 70 THEN 'active'
        WHEN gs % 100 < 90 THEN 'completed'
        ELSE 'dropped'
    END,
    timestamp with time zone '2023-09-01 00:00:00+03' + (gs % 900) * interval '1 day',
    timestamp with time zone '2023-09-01 00:00:00+03' + (gs % 900) * interval '1 day' + (gs % 45) * interval '1 day'
FROM generate_series(1, 250000) AS gs;
