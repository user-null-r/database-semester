SELECT rolname, rolcanlogin
FROM pg_roles
WHERE rolname IN ('admin', 'app', 'readonly')
ORDER BY rolname;

SELECT
    'admin' AS role_name,
    has_database_privilege('admin', 'Deanery', 'CONNECT') AS can_connect,
    has_schema_privilege('admin', 'public', 'USAGE') AS can_use_public_schema,
    has_table_privilege('admin', 'public."user"', 'SELECT') AS can_select_user,
    has_table_privilege('admin', 'public."user"', 'INSERT') AS can_insert_user,
    has_table_privilege('admin', 'public."user"', 'UPDATE') AS can_update_user,
    has_table_privilege('admin', 'public."user"', 'DELETE') AS can_delete_user
UNION ALL
SELECT
    'app',
    has_database_privilege('app', 'Deanery', 'CONNECT'),
    has_schema_privilege('app', 'public', 'USAGE'),
    has_table_privilege('app', 'public."user"', 'SELECT'),
    has_table_privilege('app', 'public."user"', 'INSERT'),
    has_table_privilege('app', 'public."user"', 'UPDATE'),
    has_table_privilege('app', 'public."user"', 'DELETE')
UNION ALL
SELECT
    'readonly',
    has_database_privilege('readonly', 'Deanery', 'CONNECT'),
    has_schema_privilege('readonly', 'public', 'USAGE'),
    has_table_privilege('readonly', 'public."user"', 'SELECT'),
    has_table_privilege('readonly', 'public."user"', 'INSERT'),
    has_table_privilege('readonly', 'public."user"', 'UPDATE'),
    has_table_privilege('readonly', 'public."user"', 'DELETE')
ORDER BY role_name;

SELECT
    'admin' AS role_name,
    has_table_privilege('admin', 'public.enrollment', 'SELECT') AS can_select_enrollment,
    has_table_privilege('admin', 'public.enrollment', 'INSERT') AS can_insert_enrollment,
    has_sequence_privilege('admin', 'public.user_id_seq', 'USAGE') AS can_use_user_seq
UNION ALL
SELECT
    'app',
    has_table_privilege('app', 'public.enrollment', 'SELECT'),
    has_table_privilege('app', 'public.enrollment', 'INSERT'),
    has_sequence_privilege('app', 'public.user_id_seq', 'USAGE')
UNION ALL
SELECT
    'readonly',
    has_table_privilege('readonly', 'public.enrollment', 'SELECT'),
    has_table_privilege('readonly', 'public.enrollment', 'INSERT'),
    has_sequence_privilege('readonly', 'public.user_id_seq', 'USAGE')
ORDER BY role_name;

SET ROLE app;
DELETE FROM role WHERE code = 'tmp_app_probe';
INSERT INTO role (code, name, status) VALUES ('tmp_app_probe', 'tmp', 'active');
DELETE FROM role WHERE code = 'tmp_app_probe';
SELECT count(*) AS app_can_read_users FROM "user";
RESET ROLE;

SET ROLE readonly;
SELECT count(*) AS readonly_can_read_users FROM "user";
RESET ROLE;
