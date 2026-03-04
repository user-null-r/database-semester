DROP INDEX IF EXISTS idx_user_home_point_gist;
DROP INDEX IF EXISTS idx_user_slot_gist;
DROP INDEX IF EXISTS idx_flow_active_period_gist;
DROP INDEX IF EXISTS idx_flow_campus_point_gist;

ANALYZE "user";
ANALYZE flow;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, home_point <-> point(37.6, 55.7) AS distance
FROM "user"
WHERE home_point IS NOT NULL
ORDER BY home_point <-> point(37.6, 55.7)
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE home_point <@ box(point(37.2, 55.5), point(37.8, 56.0));

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM flow
WHERE active_period && daterange(date '2024-09-01', date '2024-12-31', '[)');

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM flow
WHERE active_period @> date '2024-10-01';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE preferred_study_slot @> now();

CREATE INDEX idx_user_home_point_gist
    ON "user"
    USING gist (home_point);

CREATE INDEX idx_user_slot_gist
    ON "user"
    USING gist (preferred_study_slot);

CREATE INDEX idx_flow_active_period_gist
    ON flow
    USING gist (active_period);

CREATE INDEX idx_flow_campus_point_gist
    ON flow
    USING gist (campus_point);

ANALYZE "user";
ANALYZE flow;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, home_point <-> point(37.6, 55.7) AS distance
FROM "user"
WHERE home_point IS NOT NULL
ORDER BY home_point <-> point(37.6, 55.7)
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE home_point <@ box(point(37.2, 55.5), point(37.8, 56.0));

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM flow
WHERE active_period && daterange(date '2024-09-01', date '2024-12-31', '[)');

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM flow
WHERE active_period @> date '2024-10-01';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id
FROM "user"
WHERE preferred_study_slot @> now();