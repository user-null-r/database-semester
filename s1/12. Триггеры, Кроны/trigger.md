# Триггеры

## ТРИГГЕРЫ

### 1. BEFORE + ROW LEVEL + NEW: Автоматическое обновление created_at перед INSERT

Автоматически устанавливаем `created_at` в текущее время, если оно не указано при создании нового пользователя.

```sql
CREATE OR REPLACE FUNCTION update_created_at_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_at IS NULL THEN
        NEW.created_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_created_at_before_insert
BEFORE INSERT ON "user"
FOR EACH ROW
EXECUTE FUNCTION update_created_at_before_insert();
```

---

### 2. BEFORE + ROW LEVEL + NEW: Валидация email перед INSERT в user

Проверяем корректность email перед вставкой новой записи пользователя.

```sql
CREATE OR REPLACE FUNCTION validate_user_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email NOT LIKE '%@%' THEN
        RAISE EXCEPTION 'Email должен содержать символ @';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_user_email
BEFORE INSERT ON "user"
FOR EACH ROW
EXECUTE FUNCTION validate_user_email();
```

---

### 3. AFTER + ROW LEVEL + NEW: Логирование нового enrollment

Автоматически записываем в лог каждое новое зачисление студента на курс.

```sql
CREATE TABLE IF NOT EXISTS enrollment_log (
    id BIGSERIAL PRIMARY KEY,
    enrollment_id BIGINT,
    user_id BIGINT,
    flow_id BIGINT,
    action VARCHAR(20),
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_new_enrollment()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO enrollment_log (enrollment_id, user_id, flow_id, action)
    VALUES (NEW.id, NEW.user_id, NEW.flow_id, 'INSERT');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_new_enrollment
AFTER INSERT ON enrollment
FOR EACH ROW
EXECUTE FUNCTION log_new_enrollment();
```

---

### 4. AFTER + ROW LEVEL + NEW: Автоматический расчет attendance_pct при создании enrollment

Устанавливаем значение посещаемости по умолчанию (0.0), если оно не указано при создании записи о зачислении.

```sql
CREATE OR REPLACE FUNCTION set_default_attendance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.attendance_pct IS NULL THEN
        NEW.attendance_pct = 0.0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_default_attendance
BEFORE INSERT ON enrollment
FOR EACH ROW
EXECUTE FUNCTION set_default_attendance();
```

---

### 5. BEFORE + ROW LEVEL + OLD: Проверка перед удалением активного enrollment

Предотвращаем удаление активных записей о зачислении, требуя сначала изменить статус.

```sql
CREATE OR REPLACE FUNCTION prevent_delete_active_enrollment()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'active' THEN
        RAISE EXCEPTION 'Нельзя удалить активную запись enrollment. Используйте UPDATE для изменения статуса.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_delete_active_enrollment
BEFORE DELETE ON enrollment
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_active_enrollment();
```

---

### 6. AFTER + ROW LEVEL + OLD: Логирование удаления user

Сохраняем информацию об удаленных пользователях в отдельной таблице логов для аудита.

```sql
CREATE TABLE IF NOT EXISTS user_deletion_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    full_name VARCHAR(255),
    email VARCHAR(255),
    deleted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_user_deletion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_deletion_log (user_id, full_name, email)
    VALUES (OLD.id, OLD.full_name, OLD.email);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_user_deletion
AFTER DELETE ON "user"
FOR EACH ROW
EXECUTE FUNCTION log_user_deletion();
```

---

### 7. BEFORE + ROW LEVEL + NEW/OLD: Автоматическое обновление updated_at при UPDATE

Автоматически обновляем поле `updated_at` при любом изменении записи в таблицах user и flow.

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_updated_at
BEFORE UPDATE ON "user"
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_flow_updated_at
BEFORE UPDATE ON flow
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();
```

---

### 8. BEFORE + ROW LEVEL + NEW/OLD: Валидация дат в flow при UPDATE

Проверяем корректность дат при обновлении потока (начало не позже конца, дедлайн не позже окончания).

```sql
CREATE OR REPLACE FUNCTION validate_flow_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_date > NEW.end_date THEN
        RAISE EXCEPTION 'Дата начала не может быть позже даты окончания';
    END IF;
    IF NEW.add_drop_deadline > NEW.end_date THEN
        RAISE EXCEPTION 'Дедлайн добавления/удаления не может быть позже даты окончания';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_flow_dates
BEFORE UPDATE ON flow
FOR EACH ROW
EXECUTE FUNCTION validate_flow_dates();
```

---

### 9. AFTER + STATEMENT LEVEL: Подсчет общего количества enrollment после операций

Обновляем статистику по количеству зачислений после массовых INSERT, UPDATE, DELETE с таблицей enrollment.

```sql
CREATE TABLE IF NOT EXISTS enrollment_statistics (
    id BIGSERIAL PRIMARY KEY,
    total_count BIGINT,
    active_count BIGINT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_enrollment_statistics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO enrollment_statistics (total_count, active_count)
    SELECT 
        COUNT(*) as total_count,
        COUNT(*) FILTER (WHERE status = 'active') as active_count
    FROM enrollment;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_enrollment_statistics
AFTER INSERT OR UPDATE OR DELETE ON enrollment
FOR EACH STATEMENT
EXECUTE FUNCTION update_enrollment_statistics();
```

---

### 10. AFTER + STATEMENT LEVEL: Логирование массовых операций с assignment

Записываем информацию о массовых INSERT, UPDATE, DELETE с заданиями для аудита.

```sql
CREATE TABLE IF NOT EXISTS assignment_operation_log (
    id BIGSERIAL PRIMARY KEY,
    operation_type VARCHAR(20),
    affected_rows INT,
    executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_assignment_operations()
RETURNS TRIGGER AS $$
DECLARE
    op_type VARCHAR(20);
    row_count INT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        op_type := 'INSERT';
        SELECT COUNT(*) INTO row_count FROM assignment;
    ELSIF TG_OP = 'UPDATE' THEN
        op_type := 'UPDATE';
        SELECT COUNT(*) INTO row_count FROM assignment;
    ELSIF TG_OP = 'DELETE' THEN
        op_type := 'DELETE';
        SELECT COUNT(*) INTO row_count FROM assignment;
    END IF;
    
    INSERT INTO assignment_operation_log (operation_type, affected_rows)
    VALUES (op_type, row_count);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_assignment_operations
AFTER INSERT OR UPDATE OR DELETE ON assignment
FOR EACH STATEMENT
EXECUTE FUNCTION log_assignment_operations();
```

---

### 11. BEFORE + ROW LEVEL + NEW: Автоматическая установка enrolled_at при создании enrollment

Автоматически устанавливаем дату зачисления в текущее время, если она не указана при создании записи.

```sql
CREATE OR REPLACE FUNCTION set_enrolled_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.enrolled_at IS NULL THEN
        NEW.enrolled_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_enrolled_at
BEFORE INSERT ON enrollment
FOR EACH ROW
EXECUTE FUNCTION set_enrolled_at();
```

---

### 12. AFTER + ROW LEVEL + OLD: Обновление статистики при удалении lesson

Обновляем статистику по урокам после каждого удаления записи.

```sql
CREATE TABLE IF NOT EXISTS lesson_statistics (
    id BIGSERIAL PRIMARY KEY,
    total_lessons BIGINT,
    completed_lessons BIGINT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_lesson_statistics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lesson_statistics (total_lessons, completed_lessons)
    SELECT 
        COUNT(*) as total_lessons,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_lessons
    FROM lesson;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_lesson_statistics
AFTER DELETE ON lesson
FOR EACH ROW
EXECUTE FUNCTION update_lesson_statistics();
```

---

## ОТОБРАЖЕНИЕ СПИСКА ТРИГГЕРОВ

### Просмотр всех триггеров в базе данных

Получаем список всех триггеров (имя, таблица, событие, время срабатывания, уровень).

```sql
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing,
    action_orientation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

**Результат:**

| trigger_name | event_manipulation | event_object_table | action_timing | action_orientation |
|--------------|-------------------|-------------------|---------------|-------------------|
| trigger_log_assignment_operations | INSERT | assignment | AFTER | STATEMENT |
| trigger_log_assignment_operations | UPDATE | assignment | AFTER | STATEMENT |
| trigger_log_assignment_operations | DELETE | assignment | AFTER | STATEMENT |
| trigger_log_new_enrollment | INSERT | enrollment | AFTER | ROW |
| trigger_prevent_delete_active_enrollment | DELETE | enrollment | BEFORE | ROW |
| trigger_set_default_attendance | INSERT | enrollment | BEFORE | ROW |
| trigger_set_enrolled_at | INSERT | enrollment | BEFORE | ROW |
| trigger_update_enrollment_statistics | INSERT | enrollment | AFTER | STATEMENT |
| trigger_update_enrollment_statistics | UPDATE | enrollment | AFTER | STATEMENT |
| trigger_update_enrollment_statistics | DELETE | enrollment | AFTER | STATEMENT |
| trigger_validate_flow_dates | UPDATE | flow | BEFORE | ROW |
| trigger_flow_updated_at | UPDATE | flow | BEFORE | ROW |
| trigger_update_lesson_statistics | DELETE | lesson | AFTER | ROW |
| trigger_user_created_at_before_insert | INSERT | user | BEFORE | ROW |
| trigger_log_user_deletion | DELETE | user | AFTER | ROW |
| trigger_user_updated_at | UPDATE | user | BEFORE | ROW |
| trigger_validate_user_email | INSERT | user | BEFORE | ROW |

---

### Детальная информация о триггерах с функциями

Получаем полную информацию о триггерах (+ связанные функции).

```sql
SELECT 
    t.trigger_name,
    t.event_object_table as table_name,
    t.event_manipulation as event,
    t.action_timing as timing,
    t.action_orientation as level,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM information_schema.triggers t
JOIN pg_trigger pg_t ON pg_t.tgname = t.trigger_name
JOIN pg_proc p ON p.oid = pg_t.tgfoid
WHERE t.trigger_schema = 'public'
  AND pg_t.tgisinternal = false  -- Исключаем системные триггеры
ORDER BY t.event_object_table, t.trigger_name;
```

**Результат (пример для нескольких триггеров):**

| trigger_name | table_name | event | timing | level | function_name |
|--------------|------------|-------|--------|-------|---------------|
| trigger_log_new_enrollment | enrollment | INSERT | AFTER | ROW | log_new_enrollment |
| trigger_prevent_delete_active_enrollment | enrollment | DELETE | BEFORE | ROW | prevent_delete_active_enrollment |
| trigger_set_default_attendance | enrollment | INSERT | BEFORE | ROW | set_default_attendance |
| trigger_set_enrolled_at | enrollment | INSERT | BEFORE | ROW | set_enrolled_at |
| trigger_update_enrollment_statistics | enrollment | INSERT | AFTER | STATEMENT | update_enrollment_statistics |
| trigger_validate_flow_dates | flow | UPDATE | BEFORE | ROW | validate_flow_dates |
| trigger_flow_updated_at | flow | UPDATE | BEFORE | ROW | update_updated_at |
| trigger_update_lesson_statistics | lesson | DELETE | AFTER | ROW | update_lesson_statistics |
| trigger_user_created_at_before_insert | user | INSERT | BEFORE | ROW | update_created_at_before_insert |
| trigger_log_user_deletion | user | DELETE | AFTER | ROW | log_user_deletion |
| trigger_user_updated_at | user | UPDATE | BEFORE | ROW | update_updated_at |
| trigger_validate_user_email | user | INSERT | BEFORE | ROW | validate_user_email |

---
