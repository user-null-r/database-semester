-- Дополнительные типы (миграция ради миграции)

ALTER TABLE "user"
    ADD COLUMN about_text TEXT,
    ADD COLUMN profile JSONB,
    ADD COLUMN interests TEXT[],
    ADD COLUMN home_point POINT,
    ADD COLUMN preferred_study_slot TSTZRANGE;

ALTER TABLE flow
    ADD COLUMN summary_text TEXT,
    ADD COLUMN metadata JSONB,
    ADD COLUMN tags TEXT[],
    ADD COLUMN campus_point POINT,
    ADD COLUMN active_period DATERANGE;
