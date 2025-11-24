# Project Manager DB

База данных для проекта "Project Manager" - система управления проектами.

# ProjectManagerDB — Описание DDL

В этой папке находятся скрипты создания таблиц для базы данных "Project Manager". Ниже краткое описание каждой таблицы и её полей.

---

## users
- id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- username — VARCHAR(255), NOT NULL, UNIQUE  
- email — VARCHAR(255), NOT NULL, UNIQUE  
- password_hash — TEXT, NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: хранит пользователей приложения.

---

## projects
- project_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- project_name — VARCHAR(255), NOT NULL  
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
- task_name — VARCHAR(255), NOT NULL  
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
- file_name — VARCHAR(255), NOT NULL  
- file_path — TEXT, NOT NULL  
- uploaded_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()

Примечание: хранит информацию о файлах, прикреплённых к задачам tasks(task_id). Удаление задачи удаляет файлы, приложенные к ней.

---

## teams
- team_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- team_name — VARCHAR(128), NOT NULL  
- created_at — TIMESTAMP WITH TIME ZONE, DEFAULT now()  
- owner_id — BIGINT, REFERENCES users(id) ON DELETE SET NULL

Примечание: owner_id ссылается на пользователя, при удалении пользователя становится NULL.

---

## team_members
- team_member_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- team_id — BIGINT NOT NULL, REFERENCES teams(team_id) ON DELETE CASCADE  
- user_id — BIGINT NOT NULL, REFERENCES users(id) ON DELETE CASCADE  
- role — VARCHAR(32), NOT NULL, DEFAULT 'member'

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
- priority_level — VARCHAR(32), NOT NULL, UNIQUE  
- color_code — VARCHAR(32), NOT NULL, UNIQUE

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
- dependency_type — VARCHAR(32), NOT NULL  
- UNIQUE (task_id, dependent_task_id)

Примечание: моделирует зависимости между задачами (направленные связи).

---

## statuses
- status_id — BIGINT GENERATED ALWAYS AS IDENTITY, PRIMARY KEY  
- status — VARCHAR(32), NOT NULL, UNIQUE

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

## Индексы (описание и назначение)

Ниже перечислены индексы из DDL/create_indexes.sql с кратким описанием назначения. Primary key и UNIQUE уже создают соответствующие индексы автоматически.

- **idx_users_email_username ON users(email, username)**  
  Цель: ускоряет поиск/фильтрацию по email и по комбинации email+username (например, при входе или проверке уникальности). Порядок колонок важен — индекс оптимален для фильтраций по email и по email + username.

- **idx_tasks_task_name ON tasks(task_name)**
  Цель: ускоряет поиск задач по имени (поиск/фильтрация по task_name).

- **idx_tasks_project_id ON tasks(project_id)**  
  Цель: ускоряет соединения и фильтрацию задач по проекту (выборка задач проекта).

- **idx_tasks_assigned_to ON tasks(assigned_to)**  
  Цель: ускоряет выборку задач, назначенных на конкретного пользователя.

- **idx_tasks_assigned_to_status ON tasks(assigned_to, status_id)**  
  Цель: оптимизация частых запросов с фильтром по исполнителю и статусу одновременно. Используется для фильтрации задач, назначенных пользователю.

- **idx_tasks_project_id_status ON tasks(project_id, status_id)**  
  Цель: ускоряет выборку и агрегацию задач по проекту с учётом статуса (например, список задач проекта с фильтром по статусу или группировка).

- **idx_change_history_task_id ON change_history(task_id)**  
  Цель: ускоряет получение журналов изменений для конкретной задачи.

- **idx_change_history_task_id_changed_by ON change_history(task_id, changed_by)**  
  Цель: ускоряет запросы по задаче и пользователю, выполнившему изменение. Используется для получения изменений конкретной задачи одним пользователем.

- **idx_comments_task_id_created_at ON comments(task_id, created_at)**  
  Цель: быстро получать комментарии задачи в порядке времени (поддерживает ORDER BY created_at при фильтрации по task_id).

- **idx_files_task_id ON files(task_id)**  
  Цель: ускоряет перечисление файлов, прикреплённых к задаче.

- **idx_task_dependencies_dependency_type ON task_dependencies(dependency_type)**  
  Цель: ускоряет фильтрацию зависимостей по типу (например, "blocks", "relates").

- **idx_team_members_user_id_team_id ON team_members(user_id, team_id)**  
  Цель: ускоряет проверку членства пользователя в командах и выборки команд по пользователю. Используется для получения участников команды.

- **idx_time_tracking_task_id ON time_tracking(task_id)**  
  Цель: ускоряет выборку записей времени для задачи.

- **idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id)**  
  Цель: оптимизация фильтрации по задаче и пользователю. Используется для получения затрат времени пользователя по задаче.

- **idx_time_tracking_task_id_entry_date ON time_tracking(task_id, entry_date)**  
  Цель: ускоряет выборки по задаче и дате (например, за день по задаче).

- **idx_time_tracking_user_id_entry_date ON time_tracking(user_id, entry_date)**  
  Цель: отчёты по пользователю за период/дату (помогает при агрегировании по дате).


Файлы в папке DDL можно использовать для создания схемы БД в PostgreSQL.

## Диаграмма базы данных

![db_schema](/Docs/ProjectManagerDB_schema.png)