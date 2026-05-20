# Project Manager DB

База данных для проекта "Project Manager" - система управления проектами.

## ProjectManagerDB — Описание DDL

В этой папке находятся скрипты создания объектов БД: таблиц, индексов, хранимых процедур, триггеров.

Ниже приводится краткое описание объектов.

---

### Таблицы

**PRIORITIES**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- priority_level — VARCHAR(32), NOT NULL, UNIQUE

Примечание: справочная таблица уровней приоритетов.

---

**STATUSES**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- status — VARCHAR(32), NOT NULL, UNIQUE

Примечание: справочная таблица статусов.

---

**USERS**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- username — VARCHAR(255), NOT NULL, UNIQUE  
- email — VARCHAR(255), NOT NULL, UNIQUE  
- password_hash — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: хранит пользователей приложения.

---

**PROJECTS**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- name — VARCHAR(255), NOT NULL  
- description — TEXT  
- start_date — DATE  
- end_date — DATE  
- status_id — BIGINT NOT NULL REFERENCES statuses(id)  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()  
- owner_id — BIGINT NOT NULL REFERENCES users(id)

Примечание: хранит проекты. owner_id ссылается на users, поле status_id ссылается на таблицу statuses.

---

**TASKS**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- name — VARCHAR(255), NOT NULL  
- description — TEXT  
- due_date — DATE  
- status_id — BIGINT NOT NULL REFERENCES statuses(id)  
- priority_id — BIGINT REFERENCES priorities(id)  
- project_id — BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE  
- assigned_to — BIGINT REFERENCES users(id) ON DELETE SET NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: поле status_id ссылается на таблицу statuses, поле priority_id ссылается на таблицу priorities. Поле project_id ссылается на таблицу projects, удаление проекта приводит к удалению задач (CASCADE). Поле assigned_to ссылается на таблицу users, при удалении пользователя поле assigned_to становится NULL.

---

**COMMENTS**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE  
- user_id — BIGINT REFERENCES users(id) ON DELETE SET NULL  
- content — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: комментарии привязаны к задачам, удаление пользователя обнуляет user_id, удаление задачи удаляет комментарий.

---

**FILES**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE  
- file_name — VARCHAR(255), NOT NULL  
- file_path — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: хранит информацию о файлах, прикреплённых к задачам. Удаление задачи удаляет файлы, приложенные к ней.

---

**TEAMS**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- team_name — VARCHAR(128), NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()  
- owner_id — BIGINT REFERENCES users(id) ON DELETE SET NULL

Примечание: owner_id ссылается на пользователя, при удалении пользователя становится NULL.

---

**TEAM_MEMBERS**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- team_id — BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE  
- user_id — BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE  
- role — team_role NOT NULL DEFAULT 'member' (enum: 'lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member')

Примечание: таблица связи пользователей и команд.

---

**LOG_HISTORY**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE  
- changed_by — BIGINT REFERENCES users(id) ON DELETE SET NULL  
- change_type — change_type NOT NULL (enum: 'status', 'name', 'description', 'comment', 'assignment', 'due_date', 'priority')  
- old_value — TEXT  
- new_value — TEXT  
- changed_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: журнал изменений по задачам.

---

**TIME_TRACKING**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE  
- user_id — BIGINT REFERENCES users(id) ON DELETE SET NULL  
- hours_spent — NUMERIC(6,2) NOT NULL CHECK (hours_spent >= 0)  
- entry_date — DATE NOT NULL DEFAULT CURRENT_DATE

Примечание: учёт затраченного времени по задачам.

---

**TASK_DEPENDENCIES**
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- task_id — BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE  
- dependent_task_id — BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE  
- dependency_type — dependency_type NOT NULL (enum: 'blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of')  
- UNIQUE (task_id, dependent_task_id)

Примечание: моделирует зависимости между задачами (направленные связи).

---

### Заметки по связям
- projects.owner_id → users.id  
- projects.status_id → statuses.id  
- tasks.project_id → projects.id  
- tasks.status_id → statuses.id  
- tasks.priority_id → priorities.id  
- tasks.assigned_to → users.id  
- comments.task_id → tasks.id  
- comments.user_id → users.id  
- files.task_id → tasks.id  
- teams.owner_id → users.id  
- team_members.team_id → teams.id
- team_members.user_id → users.id  
- log_history.task_id → tasks.id
- log_history.changed_by → users.id  
- time_tracking.task_id → tasks.id
- time_tracking.user_id → users.id  
- task_dependencies.task_id / dependent_task_id → tasks.id

---

## Индексы (описание и назначение)

Ниже перечислены индексы из DDL/create_indexes.sql с кратким описанием назначения. Primary key и UNIQUE уже создают соответствующие индексы автоматически.

- **idx_users_username ON users(username)**  
  Цель: уникальный индекс для быстрого поиска по имени пользователя.

- **idx_tasks_task_name_gin ON tasks USING gin (to_tsvector(task_name))**  
  Цель: GIN индекс для полнотекстового поиска по имени задачи.

- **idx_tasks_task_description_gin ON tasks USING gin (to_tsvector(task_description))**  
  Цель: GIN индекс для полнотекстового поиска по описанию задачи.

- **idx_tasks_assigned_to_status ON tasks(assigned_to, status_id)**  
  Цель: составной индекс для поиска задач по назначенному пользователю и сортировки или группировки по статусу.

- **idx_tasks_project_id_status ON tasks(project_id, status_id)**  
  Цель: ускоряет выборку и агрегацию задач по проекту с учётом статуса (например, список задач проекта с фильтром по статусу или группировка).

- **idx_log_history_task_id ON log_history(task_id)**  
  Цель: поиск истории изменений по task_id.

- **idx_comments_task_id_created_at ON comments(task_id, created_at)**  
  Цель: поиск комментариев по task_id и сортировка по created_at.

- **idx_files_task_id ON files(task_id)**  
  Цель: поиск файлов по task_id.

- **idx_task_dependencies_task_id ON task_dependencies(task_id)**  
  Цель: поиск зависимых задач по task_id.

- **idx_team_members_team_id ON team_members(team_id)**  
  Цель: поиск пользователей в команде.

- **idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id) INCLUDE (hours_spent, entry_date)**  
  Цель: поиск записей по task_id и user_id с включением полей hours_spent и entry_date.

- **idx_time_tracking_task_id_entry_date ON time_tracking(task_id, entry_date) INCLUDE (hours_spent)**  
  Цель: поиск записей по task_id и entry_date.

- **idx_time_tracking_user_id_entry_date ON time_tracking(user_id, entry_date) INCLUDE (task_id, hours_spent)**  
  Цель: поиск записей по user_id и entry_date для анализа активности пользователя.

Файлы в папке DDL можно использовать для создания схемы БД в PostgreSQL.

## Диаграмма базы данных

![db_schema](/Docs/ProjectManagerDB_schema.png)