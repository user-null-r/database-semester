## 1НФ
1. `auditorium_id` в таблицах `exam` и `lesson` не атомарная в случае если выделено несколько аудиторий → сделать таблицы `lesson_classroom` и `exam_classroom` для связи many-to-many
2. Аналогично с `role_id` в таблице `user` → сделать таблицу `user_role` для связи many-to-many
3. Поле `Phones` у преподавателей не атомарное → вынести в отдельную таблицу `lecturer_phone(lecturer_id, phone_number)`

## 2НФ
- Соответствует форме, так как нет составных первичных ключей, и все неключевые атрибуты зависят только от ключа.

## 3НФ
1. `middle_name` в `user` дублирует информацию из `full_name` → удалить `middle_name`
2. `attendance_pct`, `current_score`, `final_grade` зависят от `role` (применяются только если роль — студент) в таблице `enrollment` → убрать `role` и вносить в эту таблицу только студентов, а для учёта преподавателей сделать many-to-many связь с `discipline` через таблицу `discipline_teacher`
3. В таблице `classroom` атрибут `building` зависит от `campus` → убрать `campus` и включить всю информацию в `building`
4. Временные и статусные поля (`status`, `start_time`, `end_time`) в `exam` и `assignment` частично зависят от состояния, а не ключа → статусы вынести в справочники `exam_status` и `assignment_status`
5. Если `lecturer` в таблице `discipline` дублирует данные из `user`, заменить его на внешний ключ `lecturer_id`

## БКНФ
- Соответствует форме, так как после приведения к 3НФ не осталось зависимостей от неключевых атрибутов, составных ключей нет.

## Дополнительные правки
1. Заменить внешний ключ `unit_id` в `discipline` на `flow_id`
2. Заменить внешний ключ `flow_id` в `assignment` на `discipline_id`
3. Заменить внешний ключ `flow_id` в `exam` на `discipline_id`
4. Добавить справочники `exam_status` и `assignment_status`
5. Вынести телефоны преподавателей в отдельную таблицу `lecturer_phone`