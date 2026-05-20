SET search_path = proj_manager, PUBLIC;

/*
  Хранимые процедуры для управления проектами, задачами, командами и отслеживанием времени.
  Каждая процедура принимает входные параметры для необходимых полей и возвращает код ошибки через OUT-параметр.
  Код ошибки:
    0 - Успех
    100 - Нарушение ограничений (NOT NULL, FOREIGN KEY, CHECK)
    200 - Другая ошибка (например, синтаксическая ошибка, ошибка соединения и т.д.)
    300 - Не найдено (например, проект, задача или пользователь не существует)
    400 - Неверное значение (например, недопустимый статус, приоритет, роль и т.д.)
*/

-- Projects
-- Хранимая процедура для создания нового проекта
CREATE OR REPLACE PROCEDURE create_project(
    p_name VARCHAR(255),
    p_description TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_status VARCHAR(32),
    p_owner_name VARCHAR(255),
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted_project_id BIGINT;
    v_status_id BIGINT;
    v_owner_id BIGINT;
BEGIN
    p_error_code := 0;
    -- Проверяем, что статус является допустимым значением

    SELECT id INTO v_status_id FROM statuses WHERE status = p_status;
    IF v_status_id IS NULL THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid status: %. Valid values are: active, completed, on_hold, cancelled, planned', p_status;
        RETURN;
    END IF;

    SELECT id INTO v_owner_id FROM users WHERE username = p_owner_name;
    IF v_owner_id IS NULL THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid owner: %. User does not exist', p_owner_name;
        RETURN;
    END IF;

    INSERT INTO projects (name, description, start_date, end_date, status_id, owner_id)
    VALUES (p_name, p_description, p_start_date, p_end_date, v_status_id, v_owner_id)
    RETURNING id INTO v_inserted_project_id;

    RAISE NOTICE 'Project created successfully with id: %', v_inserted_project_id;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error creating project: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error creating project: %', SQLERRM;
END;
$$;

-- Хранимая процедура для обновления проекта
CREATE OR REPLACE PROCEDURE update_project(
    p_project_id BIGINT,
    p_name VARCHAR(255) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_status VARCHAR(32) DEFAULT NULL,
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status_id BIGINT;
BEGIN
    p_error_code := 0;

    IF p_status IS NOT NULL THEN
        SELECT id INTO v_status_id FROM statuses WHERE status = p_status;
        IF v_status_id IS NULL THEN
            p_error_code := 400;
            RAISE NOTICE 'Invalid status: %. Valid values are: active, completed, on_hold, cancelled, planned', p_status;
            RETURN;
        END IF;
    END IF;

    UPDATE projects SET
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        start_date = COALESCE(p_start_date, start_date),
        end_date = COALESCE(p_end_date, end_date),
        status_id = COALESCE((SELECT id FROM statuses WHERE status = p_status), status_id)
    WHERE id = p_project_id;

    IF NOT FOUND THEN
        p_error_code := 300;
        RAISE NOTICE 'Project with id % does not exist', p_project_id;
    ELSE
        RAISE NOTICE 'Project with id % updated successfully', p_project_id;
    END IF;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error updating project: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error updating project: %', SQLERRM;
END;
$$;

-- Tasks
-- Хранимая процедура для создания новой задачи
CREATE OR REPLACE PROCEDURE create_task(
    p_name VARCHAR(255),
    p_description TEXT,
    p_due_date DATE,
    p_status VARCHAR(32),
    p_priority VARCHAR(32),
    p_project_id BIGINT,
    p_user_name VARCHAR(255) DEFAULT NULL,
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted_task_id BIGINT;
    v_status_id BIGINT;
    v_priority_id BIGINT;
    v_user_id BIGINT;
BEGIN
    p_error_code := 0;

    -- Получаем ID статуса
    SELECT id INTO v_status_id FROM statuses WHERE status = p_status;
    IF v_status_id IS NULL THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid status: %. Valid values are: active, completed, on_hold, cancelled, planned', p_status;
        RETURN;
    END IF;

    -- Получаем ID приоритета
    SELECT id INTO v_priority_id FROM priorities WHERE priority_level = p_priority;
    IF v_priority_id IS NULL THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid priority: %. Valid values are: low, medium, high', p_priority;
        RETURN;
    END IF;

    -- Получаем ID пользователя
    SELECT id INTO v_user_id FROM users WHERE username = p_user_name;
    IF v_user_id IS NULL THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid user: %. User does not exist', p_user_name;
        RETURN;
    END IF;


    INSERT INTO tasks (name, description, due_date, status_id, priority_id, project_id, assigned_to)
    VALUES (
        p_name,
        p_description,
        p_due_date,
        v_status_id,
        v_priority_id,
        p_project_id,
        v_user_id
    )
    RETURNING id INTO v_inserted_task_id;

    RAISE NOTICE 'Task created successfully with id: %', v_inserted_task_id;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error creating task: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error creating task: %', SQLERRM;
END;
$$;

-- Хранимая процедура для записи изменений задачи в log_history
CREATE OR REPLACE PROCEDURE log_task_field_change(
    p_task_id BIGINT,
    p_changed_by_id BIGINT,
    p_change_type change_type,
    p_old_value TEXT,
    p_new_value TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
    VALUES (p_task_id, p_changed_by_id, p_change_type, p_old_value, p_new_value);
END;
$$;

-- Хранимая процедура для обновления задачи с логированием изменений в log_history
CREATE OR REPLACE PROCEDURE update_task_with_log(
    p_task_id BIGINT,
    p_changed_by VARCHAR(255),
    p_name VARCHAR(255) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_status VARCHAR(32) DEFAULT NULL,
    p_priority VARCHAR(32) DEFAULT NULL,
    p_assigned_to VARCHAR(255) DEFAULT NULL,
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_task RECORD;
    v_change_count INT := 0;
    v_changed_by_id BIGINT;
    v_status_id BIGINT;
    v_priority_id BIGINT;
    v_assigned_to_id BIGINT;
BEGIN
    p_error_code := 0;
    -- Получаем текущие данные задачи для сравнения и логирования изменений
    SELECT * INTO v_old_task FROM tasks WHERE id = p_task_id;
    
    -- Проверяем, существует ли задача
    IF v_old_task IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'Task with id % does not exist', p_task_id;
        RETURN;
    END IF;

    -- Получаем ID пользователя, который вносит изменения
    SELECT id INTO v_changed_by_id FROM users WHERE username = p_changed_by;
    IF v_changed_by_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'User % does not exist', p_changed_by;
        RETURN;
    END IF;

    -- Обновляем имя задачи, если предоставлено и отличается от текущего
    IF p_name IS NOT NULL AND v_old_task.name IS DISTINCT FROM p_name THEN
        CALL log_task_field_change(p_task_id, v_changed_by_id, 'name'::change_type, v_old_task.name, p_name);
        UPDATE tasks SET name = p_name WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем описание задачи, если предоставлено и отличается от текущего
    IF p_description IS NOT NULL AND v_old_task.description IS DISTINCT FROM p_description THEN
        CALL log_task_field_change(p_task_id, v_changed_by_id, 'description'::change_type, v_old_task.description, p_description);
        UPDATE tasks SET description = p_description WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем дату окончания, если предоставлена и отличается от текущей
    IF p_due_date IS NOT NULL AND v_old_task.due_date IS DISTINCT FROM p_due_date THEN
        CALL log_task_field_change(p_task_id, v_changed_by_id, 'due_date'::change_type, v_old_task.due_date::TEXT, p_due_date::TEXT);
        UPDATE tasks SET due_date = p_due_date WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем статус, если предоставлен и отличается от текущего
    IF p_status IS NOT NULL THEN

        -- Проверяем, что статус является допустимым значением
        SELECT id INTO v_status_id FROM statuses WHERE status = p_status;
        IF v_status_id IS NULL THEN
            p_error_code := 400;
            RAISE NOTICE 'Invalid status: %. Valid values are: active, completed, on_hold, cancelled, planned', p_status;
            RETURN;
        END IF;

        IF v_old_task.status_id <> v_status_id THEN
            CALL log_task_field_change(
                p_task_id, 
                v_changed_by_id, 
                'status'::change_type, 
                (SELECT status FROM statuses WHERE id = v_old_task.status_id)::TEXT, 
                p_status::TEXT);
            UPDATE tasks SET status_id = v_status_id WHERE id = p_task_id;
            v_change_count := v_change_count + 1;
        END IF;
    END IF;

    -- Обновляем приоритет, если предоставлен и отличается от текущего
    IF p_priority IS NOT NULL THEN
        SELECT id INTO v_priority_id FROM priorities WHERE priority_level = p_priority;
        IF v_priority_id IS NULL THEN
            p_error_code := 400;
            RAISE NOTICE 'Invalid priority: %. Valid values are: low, medium, high', p_priority;
            RETURN;
        END IF;

        IF v_old_task.priority_id <> v_priority_id THEN
            CALL log_task_field_change(
                p_task_id, 
                v_changed_by_id, 
                'priority'::change_type, 
                (SELECT priority_level FROM priorities WHERE id = v_old_task.priority_id)::TEXT, 
                p_priority::TEXT
            );
            UPDATE tasks SET priority_id = v_priority_id WHERE id = p_task_id;
            v_change_count := v_change_count + 1;
        END IF;
    END IF;

    -- Обновляем назначенного пользователя, если предоставлен и отличается от текущего
    IF p_assigned_to IS NOT NULL THEN
        SELECT id INTO v_assigned_to_id FROM users WHERE username = p_assigned_to;
        IF v_assigned_to_id IS NULL THEN
            p_error_code := 400;
            RAISE NOTICE 'Invalid user: %. User does not exist', p_assigned_to;
            RETURN;
        END IF;

        IF v_old_task.assigned_to <> v_assigned_to_id THEN
            CALL log_task_field_change(
                p_task_id, 
                v_changed_by_id, 
                'assignment'::change_type, 
                (SELECT username FROM users WHERE id = v_old_task.assigned_to)::TEXT, 
                p_assigned_to::TEXT
            );
            UPDATE tasks SET assigned_to = v_assigned_to_id WHERE id = p_task_id;
            v_change_count := v_change_count + 1;
        END IF;
    END IF;

    -- Конечное уведомление о количестве изменений
    IF v_change_count > 0 THEN
        RAISE NOTICE 'Task % updated successfully. % field(s) changed and logged.', p_task_id, v_change_count;
    ELSE
        RAISE NOTICE 'Task % not updated: no changes provided.', p_task_id;
    END IF;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error updating task: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error updating task: %', SQLERRM;
END;
$$;

-- Добавление комментария к задаче с логированием в log_history
CREATE OR REPLACE PROCEDURE add_comment_to_task(
    p_task_id BIGINT,
    p_user_name VARCHAR(128),
    p_comment_content TEXT,
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    p_error_code := 0;

    -- Проверяем, что задача существует
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE id = p_task_id) THEN
        p_error_code := 300;
        RAISE NOTICE 'Task with id % does not exist', p_task_id;
        RETURN;
    END IF;

    -- Получаем ID пользователя, который добавляет комментарий
    SELECT id INTO v_user_id FROM users WHERE username = p_user_name;
    IF v_user_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'User % does not exist', p_user_name;
        RETURN;
    END IF;

    -- Добавляем комментарий к задаче
    INSERT INTO comments (task_id, user_id, content)
    VALUES (p_task_id, v_user_id, p_comment_content);

    -- Логируем добавление комментария в log_history
    CALL log_task_field_change(
        p_task_id, 
        v_user_id, 
        'comment'::change_type, 
        NULL, 
        p_comment_content
    );

    RAISE NOTICE 'Comment added to task % and logged.', p_task_id;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error adding comment: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error adding comment: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE add_file_to_task(
    p_task_id BIGINT,
    p_file_name VARCHAR(255),
    p_file_path TEXT,
    p_file_type VARCHAR(32),
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_error_code := 0;

    -- Проверяем, что задача существует
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE id = p_task_id) THEN
        p_error_code := 300;
        RAISE NOTICE 'Task with id % does not exist', p_task_id;
        RETURN;
    END IF;

    -- Проверяем, что file_type является допустимым значением enum
    IF p_file_type NOT IN ('zip', 'rar', '7z', 'pdf', 'log', 'doc', 'other') THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid file_type: %. Valid values are: zip, rar, 7z, pdf, log, doc, other', p_file_type;
        RETURN;
    END IF;

    INSERT INTO files (task_id, file_name, file_path, file_type)
    VALUES (p_task_id, p_file_name, p_file_path, p_file_type::file_type);

    RAISE NOTICE 'File % added to task % successfully.', p_file_name, p_task_id;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error adding file: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error adding file: %', SQLERRM;
END;
$$;

-- Хранимая процедура для установки зависимости между задачами
CREATE OR REPLACE PROCEDURE set_task_dependency(
    p_task_id BIGINT,
    p_dependent_task_id BIGINT,
    p_dependency_type VARCHAR(32),
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_error_code := 0;

    -- Проверяем, что обе задачи существуют
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE id = p_task_id) THEN
        p_error_code := 300;
        RAISE NOTICE 'Task with id % does not exist', p_task_id;
        RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE id = p_dependent_task_id) THEN
        p_error_code := 300;
        RAISE NOTICE 'Dependent task with id % does not exist', p_dependent_task_id;
        RETURN;
    END IF;

    -- Проверяем, что тип зависимости является допустимым значением enum
    IF p_dependency_type NOT IN ('blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of') THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid dependency_type: %. Valid values are: blocks, relates_to, duplicates, predecessor_of, successor_of', p_dependency_type;
        RETURN;
    END IF;

    INSERT INTO task_dependencies (task_id, dependent_task_id, dependency_type)
    VALUES (p_task_id, p_dependent_task_id, p_dependency_type::dependency_type);

    RAISE NOTICE 'Task dependency set successfully';

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error setting task dependency: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error setting task dependency: %', SQLERRM;
END;
$$;

-- Teams
-- Хранимая процедура для создания новой команды
CREATE OR REPLACE PROCEDURE create_team(
    p_team_name VARCHAR(128),
    p_owner_name VARCHAR(128),
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted_team_id BIGINT;
    v_owner_id BIGINT;
BEGIN
    p_error_code := 0;
    -- Получаем ID владельца команды
    SELECT id INTO v_owner_id FROM users WHERE username = p_owner_name;
    IF v_owner_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'Invalid owner: %. User does not exist', p_owner_name;
        RETURN;
    END IF;

    INSERT INTO teams (team_name, owner_id)
    VALUES (p_team_name, p_owner_id)
    RETURNING id INTO v_inserted_team_id;

    RAISE NOTICE 'Team created successfully with id: %', v_inserted_team_id;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error creating team: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error creating team: %', SQLERRM;
END;
$$;

-- Хранимая процедура для добавления участника в команду
CREATE OR REPLACE PROCEDURE add_team_member(
    p_team_name VARCHAR(128),
    p_user_name VARCHAR(128),
    p_role VARCHAR(32) DEFAULT 'member',
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_team_id BIGINT;
    v_user_id BIGINT;
BEGIN
    p_error_code := 0;
    -- Проверяем, что роль является допустимым значением enum
    IF p_role NOT IN ('lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member') THEN
        p_error_code := 400;
        RAISE NOTICE 'Invalid role: %. Valid values are: lead, developer, tester, devops, manager, analyst, member', p_role;
        RETURN;
    END IF;

    -- Получаем ID команды
    SELECT id INTO v_team_id FROM teams WHERE team_name = p_team_name;
    IF v_team_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'Team % does not exist', p_team_name;
        RETURN;
    END IF;

    -- Получаем ID пользователя
    SELECT id INTO v_user_id FROM users WHERE username = p_user_name;
    IF v_user_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'User % does not exist', p_user_name;
        RETURN;
    END IF;

    INSERT INTO team_members (team_id, user_id, role)
    VALUES (v_team_id, v_user_id, p_role::team_role);

    RAISE NOTICE 'User % added to team % as % successfully.', p_user_name, p_team_name, p_role;
        
EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error adding team member: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error adding team member: %', SQLERRM;
END;
$$;

-- Time tracking
-- Хранимая процедура для добавления записи о затраченном времени
CREATE OR REPLACE PROCEDURE add_time_entry(
    p_task_id BIGINT,
    p_user_name VARCHAR(128),
    p_entry_date DATE,
    p_hours_spent NUMERIC(5,2),
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    p_error_code := 0;
    
    -- Проверяем, что задача существует
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE id = p_task_id) THEN
        p_error_code := 300;
        RAISE NOTICE 'Task with id % does not exist', p_task_id;
        RETURN;
    END IF;

    -- Получаем ID пользователя, который добавляет запись о времени
    SELECT id INTO v_user_id FROM users WHERE username = p_user_name;
    IF v_user_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'User % does not exist', p_user_name;
        RETURN;
    END IF;

    INSERT INTO time_tracking (task_id, user_id, entry_date, hours_spent)
    VALUES (p_task_id, v_user_id, p_entry_date, p_hours_spent);

    RAISE NOTICE 'Time entry added successfully for task % by user %.', p_task_id, p_user_name;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION OR CHECK_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error adding time entry: constraint violation';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error adding time entry: %', SQLERRM;
END;
$$;

-- Users
-- Хранимая процедура для создания нового пользователя
CREATE OR REPLACE PROCEDURE create_user(
    p_username VARCHAR(255),
    p_email VARCHAR(255),
    p_password_hash TEXT,
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted_user_id BIGINT;
BEGIN
    p_error_code := 0;

    INSERT INTO users (username, email, password_hash)
    VALUES (p_username, p_email, p_password_hash)
    RETURNING id INTO v_inserted_user_id;

    RAISE NOTICE 'User created successfully with id: %', v_inserted_user_id;

EXCEPTION
    WHEN NOT_NULL_VIOLATION OR FOREIGN_KEY_VIOLATION OR UNIQUE_VIOLATION THEN
        p_error_code := 100;
        RAISE NOTICE 'Error creating user: constraint violation (username or email may already exist)';
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error creating user: %', SQLERRM;
END;
$$;

-- Хранимая процедура для деактивации пользователя
CREATE OR REPLACE PROCEDURE deactivate_user(
    p_username VARCHAR(255),
    OUT p_error_code INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    p_error_code := 0;

    -- Получаем ID пользователя
    SELECT id INTO v_user_id FROM users WHERE username = p_username;
    IF v_user_id IS NULL THEN
        p_error_code := 300;
        RAISE NOTICE 'User % does not exist', p_username;
        RETURN;
    END IF;

    -- Деактивируем пользователя
    UPDATE users SET is_active = FALSE WHERE id = v_user_id;

    RAISE NOTICE 'User % deactivated successfully.', p_username;

EXCEPTION
    WHEN OTHERS THEN
        p_error_code := 200;
        RAISE NOTICE 'Error deactivating user: %', SQLERRM;
END;
$$;