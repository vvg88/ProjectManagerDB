# Project Manager DB

База данных для проекта "Project Manager" - система управления проектами.

# ProjectManagerDB — Описание DDL

В этой папке находятся скрипты создания таблиц для базы данных "Project Manager". Ниже краткое описание каждой таблицы и её полей.

---

## users
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- username — TEXT, NOT NULL, UNIQUE  
- email — TEXT  
- password_hash — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: хранит пользователей приложения.

---

## projects
- project_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- project_name — TEXT, NOT NULL  
- description — TEXT  
- start_date — DATE  
- end_date — DATE  
- status_id — BIGINT NOT NULL REFERENCES statuses(status_id)  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()  
- owner_id — BIGINT NOT NULL, REFERENCES users(id)

Примечание: owner_id ссылается на users, поле status_id ссылается на таблицу statuses.

---

## tasks
- task_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_name — TEXT, NOT NULL  
- description — TEXT  
- due_date — DATE  
- status_id — BIGINT NOT NULL REFERENCES statuses(status_id)  
- priority_id — BIGINT REFERENCES priorities(priority_id)  
- project_id — BIGINT NOT NULL, REFERENCES projects(project_id) ON DELETE CASCADE  
- assigned_to — BIGINT, REFERENCES users(id) ON DELETE SET NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: поле status_id ссылается на таблицу statuses, поле priority_id ссылается на таблицу priorities. Поле project_id ссылается на таблицу projects, удаление проекта приводит к удалению задач (CASCADE). Поле assigned_to ссылается на таблицу users, при удалении пользователя поле assigned_to становится NULL.

---

## comments
- comment_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL, REFERENCES tasks(task_id) ON DELETE CASCADE  
- user_id — BIGINT, REFERENCES users(id) ON DELETE SET NULL  
- content — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: комментарии привязаны к задачам, удаление пользователя обнуляет user_id, удаление задачи удаляет комментарий.

---

## files
- file_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL, REFERENCES tasks(task_id) ON DELETE CASCADE  
- file_name — TEXT, NOT NULL  
- file_path — TEXT, NOT NULL  
- uploaded_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: хранит информацию о файлах, прикреплённых к задачам tasks(task_id). Удаление задачи удаляет файлы, приложенные к ней.

---

## teams
- team_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- team_name — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()  
- owner_id — BIGINT, REFERENCES users(id) ON DELETE SET NULL

Примечание: owner_id ссылается на пользователя, при удалении пользователя становится NULL.

---

## team_members
- team_member_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- team_id — BIGINT NOT NULL, REFERENCES teams(team_id) ON DELETE CASCADE  
- user_id — BIGINT NOT NULL, REFERENCES users(id) ON DELETE CASCADE  
- role — TEXT, NOT NULL, DEFAULT 'member'

Примечание: таблица связи пользователей и команд.

---

## change_history
- change_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL, REFERENCES tasks(task_id) ON DELETE CASCADE  
- changed_by — BIGINT, REFERENCES users(id) ON DELETE SET NULL  
- change_type — TEXT, NOT NULL  
- old_value — TEXT  
- new_value — TEXT  
- changed_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: журнал изменений по задачам.

---

## priorities
- priority_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- priority_level — TEXT, NOT NULL, UNIQUE  
- color_code — TEXT

Примечание: справочная таблица уровней приоритетов.

---

## time_tracking
- time_entry_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL, REFERENCES tasks(task_id) ON DELETE CASCADE  
- user_id — BIGINT, REFERENCES users(id) ON DELETE SET NULL  
- hours_spent — NUMERIC(6,2), NOT NULL, CHECK (hours_spent >= 0)  
- entry_date — DATE, NOT NULL, DEFAULT CURRENT_DATE

Примечание: учёт затраченного времени по задачам.

---

## task_dependencies
- dependency_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL, REFERENCES tasks(task_id) ON DELETE CASCADE  
- dependent_task_id — BIGINT NOT NULL, REFERENCES tasks(task_id) ON DELETE CASCADE  
- dependency_type — TEXT, NOT NULL  
- UNIQUE (task_id, dependent_task_id)

Примечание: моделирует зависимости между задачами (направленные связи).

---

## statuses
- status_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- status — TEXT, NOT NULL, UNIQUE

Примечание: справочная таблица статусов.

---

## Заметки по связям
- projects.owner_id → users.id  
- projects.status_id → statuses.status_id  
- tasks.project_id → projects.project_id  
- tasks.status_id → statuses.status_id  
- tasks.priority_id → priorities.priority_id  
- tasks.assigned_to → users.id  
- comments.task_id → tasks.task_id,
- comments.user_id → users.id  
- files.task_id → tasks.task_id  
- teams.owner_id → users.id  
- team_members.team_id → teams.team_id
- team_members.user_id → users.id  
- change_history.task_id → tasks.task_id
- change_history.changed_by → users.id  
- time_tracking.task_id → tasks.task_id
- time_tracking.user_id → users.id  
- task_dependencies.task_id / dependent_task_id → tasks.task_id

---

Файлы в папке DDL можно использовать для создания схемы БД в PostgreSQL.

## Диаграмма базы данных

![db_schema](/Docs/ProjectManagerDB_schema.png)