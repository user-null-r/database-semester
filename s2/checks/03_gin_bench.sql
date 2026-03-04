CREATE EXTENSION IF NOT EXISTS pg_trgm;

DROP INDEX IF EXISTS idx_user_about_text_gin;
DROP INDEX IF EXISTS idx_user_profile_gin;
DROP INDEX IF EXISTS idx_user_interests_gin;
DROP INDEX IF EXISTS idx_user_about_text_trgm_gin;

ANALYZE "user";

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE to_tsvector('russian', COALESCE(about_text, ''))
    @@ plainto_tsquery('russian', 'SQL аналитика');

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE profile @> '{"mode":"offline"}'::jsonb;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE interests && ARRAY['interest_5', 'topic_11'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE about_text ILIKE '%аналитик%';

CREATE INDEX idx_user_about_text_gin
    ON "user"
    USING gin (to_tsvector('russian', COALESCE(about_text, '')));

CREATE INDEX idx_user_profile_gin
    ON "user"
    USING gin (profile jsonb_path_ops);

CREATE INDEX idx_user_interests_gin
    ON "user"
    USING gin (interests);

CREATE INDEX idx_user_about_text_trgm_gin
    ON "user"
    USING gin (about_text gin_trgm_ops);

ANALYZE "user";

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE to_tsvector('russian', COALESCE(about_text, ''))
    @@ plainto_tsquery('russian', 'SQL аналитика');

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE profile @> '{"mode":"offline"}'::jsonb;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE interests && ARRAY['interest_5', 'topic_11'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE about_text ILIKE '%аналитик%';