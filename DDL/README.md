# DDL Скрипты.

## create_db.sql

Создание базы данных `project_manager_db` и схемы `proj_manager`.

![db_and_schema](/Docs/pics/db_and_schema.png)

Также создается администратор созданной базы данных `pm_admin`. Кроме администратора создаются роли:
- `dev` для разработчиков с правами чтения и изменения данных.
- `analyst` для аналитиков с правами только на чтение.
Создаются пользователи `developer` и `analyst_user` с соответствующими правами.

![users_and_roles](/Docs/pics/users_and_roles.png)

## create_tables.sql

Устанавливается используемая схема `proj_manager`, создаются используемые перечисления и таблицы.

![tables](/Docs/pics/tables.png)

## create_indexes.sql

Создаются индексы таблиц.