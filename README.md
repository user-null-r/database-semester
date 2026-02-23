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

6) Проверка ролей
```bash
docker compose exec -T db psql -U admin -d Deanery < s2/checks/01_role_access.sql
```