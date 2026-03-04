1) Запуск PostgreSQL
```bash
docker compose up -d
docker ps
```

2) Проверка подключения:
```bash
psql -h localhost -p 55432 -U admin -d Deanery
```

3) Применение миграций через Flyway
```bash
docker compose run flyway
```

4) Загрузка данных
```bash
docker compose exec -T db psql -U admin -d Deanery < s2/data/01_reference_data.sql
docker compose exec -T db psql -U admin -d Deanery < s2/data/02_big_data.sql
```

5) Проверка ролей
```bash
docker compose exec -T db psql -U admin -d Deanery < s2/checks/01_role_access.sql
```

6) Бенчмарки индексов
```bash
# btree/hash (старый)
docker compose exec -T db psql -U admin -d Deanery -f s2/checks/02_index_bench.sql

# GIN: 5 запросов (создание, сканирование, сравнение операций)
docker compose exec -T db psql -U admin -d Deanery -f s2/checks/03_gin_bench.sql

# GiST: 5 запросов (создание, сканирование, сравнение операций)
docker compose exec -T db psql -U admin -d Deanery -f s2/checks/04_gist_bench.sql
```

7) 5 JOIN запросов и просмотр результатов объединения
```bash
docker compose exec -T db psql -U admin -d Deanery -f s2/checks/05_join_queries.sql
```

8) Мониторинг (Prometheus + Grafana + postgres-exporter)
```bash
docker compose --profile monitoring up -d postgres-exporter prometheus grafana
```