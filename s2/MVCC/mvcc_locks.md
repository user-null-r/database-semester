# Результаты запросов из `mvcc_locks.sql`

## 1. `xmin`, `xmax`, `ctid`

### После `INSERT`

| ctid | xmin | xmax | id | payload | note |
|------|------|------|----|---------|------|
| `(0,1)` | `836` | `0` | `1` | `v1` | `init` |

### После `UPDATE`

| ctid | xmin | xmax | id | payload | note |
|------|------|------|----|---------|------|
| `(0,2)` | `837` | `0` | `1` | `v2` | `after update` |

## 2. `t_infomask` и физические версии строки

| lp | t_xmin | t_xmax | t_ctid | t_infomask | t_infomask2 | raw_flags | combined_flags |
|----|--------|--------|--------|------------|-------------|-----------|----------------|
| `1` | `836` | `837` | `(0,2)` | `1282` | `16387` | `HEAP_HASVARWIDTH, HEAP_XMIN_COMMITTED, HEAP_XMAX_COMMITTED, HEAP_HOT_UPDATED` | `{}` |
| `2` | `837` | `0` | `(0,2)` | `10498` | `32771` | `HEAP_HASVARWIDTH, HEAP_XMIN_COMMITTED, HEAP_XMAX_INVALID, HEAP_UPDATED, HEAP_ONLY_TUPLE` | `{}` |

## 3. Те же поля в разных транзакциях

### `T1` после незакоммиченного `UPDATE`

| t1_xid | ctid | xmin | xmax | id | payload | note |
|--------|------|------|------|----|---------|------|
| `838` | `(0,3)` | `838` | `0` | `1` | `v3_uncommitted` | `updated but not committed` |

### `T2` до `COMMIT` в `T1`

| t2_xid | ctid | xmin | xmax | id | payload | note |
|--------|------|------|------|----|---------|------|
| `840` | `(0,2)` | `837` | `838` | `1` | `v2` | `after update` |

### `heap_page_items` в `T2` до `COMMIT` в `T1`

| lp | t_xmin | t_xmax | t_ctid | t_infomask | t_infomask2 | raw_flags | combined_flags |
|----|--------|--------|--------|------------|-------------|-----------|----------------|
| `1` | `836` | `837` | `(0,2)` | `1282` | `16387` | `HEAP_HASVARWIDTH, HEAP_XMIN_COMMITTED, HEAP_XMAX_COMMITTED, HEAP_HOT_UPDATED` | `{}` |
| `2` | `837` | `838` | `(0,3)` | `8450` | `49155` | `HEAP_HASVARWIDTH, HEAP_XMIN_COMMITTED, HEAP_UPDATED, HEAP_HOT_UPDATED, HEAP_ONLY_TUPLE` | `{}` |
| `3` | `838` | `0` | `(0,3)` | `10242` | `32771` | `HEAP_HASVARWIDTH, HEAP_XMAX_INVALID, HEAP_UPDATED, HEAP_ONLY_TUPLE` | `{}` |

## 4. `lock_demo`

### Исходные строки

| id | payload |
|----|---------|
| `1` | `row-1` |
| `2` | `row-2` |

### Матрица совместимости row-level locks

| Удерживаемая блокировка | `FOR KEY SHARE` | `FOR SHARE` | `FOR NO KEY UPDATE` | `FOR UPDATE` |
|-------------------------|-----------------|-------------|---------------------|--------------|
| `FOR KEY SHARE` | совместимо | совместимо | совместимо | конфликт |
| `FOR SHARE` | совместимо | совместимо | конфликт | конфликт |
| `FOR NO KEY UPDATE` | совместимо | конфликт | конфликт | конфликт |
| `FOR UPDATE` | конфликт | конфликт | конфликт | конфликт |

## 5. Дедлок

### Результаты по шагам

| Транзакция | Действие | Результат |
|------------|----------|-----------|
| `T1` | `UPDATE id = 1` | успешно |
| `T2` | `UPDATE id = 2` | успешно |
| `T1` | `UPDATE id = 2` | ожидание |
| `T2` | `UPDATE id = 1` | `deadlock detected` |
| `T1` | продолжение после отмены второй транзакции | успешно |

### Итоговое состояние `lock_demo`

| id | payload |
|----|---------|
| `1` | `row-1-t1` |
| `2` | `row-2-t1` |
