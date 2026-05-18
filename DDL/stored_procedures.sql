SET search_path = proj_manager, PUBLIC;

-- Projects
-- Хранимая процедура для создания нового проекта
CREATE OR REPLACE PROCEDURE create_project(
    p_name VARCHAR(255),
    p_description TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_status VARCHAR(32),
    p_owner_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO projects (name, description, start_date, end_date, status_id, owner_id)
    VALUES (p_name, p_description, p_start_date, p_end_date, (SELECT id FROM statuses WHERE status = p_status), p_owner_id);
END;
$$;

-- Хранимая процедура для обновления проекта
CREATE OR REPLACE PROCEDURE update_project(
    p_project_id BIGINT,
    p_name VARCHAR(255) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_status VARCHAR(32) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE projects SET
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        start_date = COALESCE(p_start_date, start_date),
        end_date = COALESCE(p_end_date, end_date),
        status_id = COALESCE((SELECT id FROM statuses WHERE status = p_status), status_id)
    WHERE id = p_project_id;
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
    p_user_name VARCHAR(255) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO tasks (name, description, due_date, status_id, priority_id, project_id, assigned_to)
    VALUES (
        p_name,
        p_description,
        p_due_date,
        (SELECT id FROM statuses WHERE status = p_status),
        (SELECT id FROM priorities WHERE priority_level = p_priority),
        p_project_id,
        (SELECT id FROM users WHERE username = p_user_name)
    );
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
    p_assigned_to VARCHAR(255) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_task RECORD;
    v_change_count INT := 0;
    v_changed_by_id BIGINT;
BEGIN
    -- Получаем текущие данные задачи для сравнения и логирования изменений
    SELECT * INTO v_old_task FROM tasks WHERE id = p_task_id;
    
    -- Проверяем, существует ли задача
    IF v_old_task IS NULL THEN
        RAISE EXCEPTION 'Task with id % does not exist', p_task_id;
    END IF;

    -- Получаем ID пользователя, который вносит изменения
    SELECT id INTO v_changed_by_id FROM users WHERE username = p_changed_by;

    -- Обновляем имя задачи, если предоставлено и отличается от текущего
    IF p_name IS NOT NULL AND v_old_task.name IS DISTINCT FROM p_name THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, v_changed_by_id, 'name'::change_type, v_old_task.name, p_name);
        UPDATE tasks SET name = p_name WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем описание задачи, если предоставлено и отличается от текущего
    IF p_description IS NOT NULL AND v_old_task.description IS DISTINCT FROM p_description THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, v_changed_by_id, 'description'::change_type, v_old_task.description, p_description);
        UPDATE tasks SET description = p_description WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем дату окончания, если предоставлена и отличается от текущей
    IF p_due_date IS NOT NULL AND v_old_task.due_date IS DISTINCT FROM p_due_date THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (p_task_id, v_changed_by_id, 'due_date'::change_type, v_old_task.due_date::TEXT, p_due_date::TEXT);
        UPDATE tasks SET due_date = p_due_date WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем статус, если предоставлен и отличается от текущего
    IF p_status IS NOT NULL AND v_old_task.status_id IS DISTINCT FROM (SELECT id FROM statuses WHERE status = p_status) THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (
            p_task_id, 
            v_changed_by_id, 
            'status'::change_type, 
            (SELECT id FROM statuses WHERE status = v_old_task.status_id)::TEXT, 
            (SELECT id FROM statuses WHERE status = p_status)::TEXT
        );
        UPDATE tasks SET status_id = (SELECT id FROM statuses WHERE status = p_status) WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем приоритет, если предоставлен и отличается от текущего
    IF p_priority IS NOT NULL AND v_old_task.priority_id IS DISTINCT FROM (SELECT id FROM priorities WHERE priority_level = p_priority) THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (
            p_task_id, 
            v_changed_by_id, 
            'priority'::change_type, 
            (SELECT id FROM priorities WHERE priority_level = v_old_task.priority_id)::TEXT, 
            (SELECT id FROM priorities WHERE priority_level = p_priority)::TEXT
        );
        UPDATE tasks SET priority_id = (SELECT id FROM priorities WHERE priority_level = p_priority) WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Обновляем назначенного пользователя, если предоставлен и отличается от текущего
    IF p_assigned_to IS NOT NULL AND v_old_task.assigned_to IS DISTINCT FROM (SELECT id FROM users WHERE username = p_assigned_to) THEN
        INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
        VALUES (
            p_task_id, 
            v_changed_by_id, 
            'assignment'::change_type, 
            (SELECT id FROM users WHERE username = v_old_task.assigned_to)::TEXT, 
            (SELECT id FROM users WHERE username = p_assigned_to)::TEXT
        );
        UPDATE tasks SET assigned_to = (SELECT id FROM users WHERE username = p_assigned_to) WHERE id = p_task_id;
        v_change_count := v_change_count + 1;
    END IF;

    -- Конечное уведомление о количестве изменений
    IF v_change_count > 0 THEN
        RAISE NOTICE 'Task % updated successfully. % field(s) changed and logged.', p_task_id, v_change_count;
    ELSE
        RAISE NOTICE 'Task % not updated: no changes provided.', p_task_id;
    END IF;

END;
$$;

-- Добавление комментария к задаче с логированием в log_history
CREATE OR REPLACE PROCEDURE add_comment_to_task(
    p_task_id BIGINT,
    p_user_name VARCHAR(128),
    p_comment_content TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    -- Получаем ID пользователя, который добавляет комментарий
    SELECT id INTO v_user_id FROM users WHERE username = p_user_name;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User % does not exist', p_user_name;
    END IF;

    -- Добавляем комментарий к задаче
    INSERT INTO comments (task_id, user_id, content)
    VALUES (p_task_id, v_user_id, p_comment_content);

    -- Логируем добавление комментария в log_history
    INSERT INTO log_history (task_id, changed_by, change_type, old_value, new_value)
    VALUES (p_task_id, v_user_id, 'comment'::change_type, NULL, p_comment_content);
    
    RAISE NOTICE 'Comment added to task % and logged.', p_task_id;
END;
$$;

-- Хранимая процедура для установки зависимости между задачами
CREATE OR REPLACE PROCEDURE set_task_dependency(
    p_task_id BIGINT,
    p_dependent_task_id BIGINT,
    p_dependency_type VARCHAR(32)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_valid_types TEXT[] := ARRAY['blocks', 'relates_to', 'duplicates', 'predecessor_of', 'successor_of'];
BEGIN
    -- Проверяем, что тип зависимости является допустимым значением enum
    IF p_dependency_type = ANY(v_valid_types) THEN
        INSERT INTO task_dependencies (task_id, dependent_task_id, dependency_type)
        VALUES (p_task_id, p_dependent_task_id, p_dependency_type::dependency_type);
    ELSE
        RAISE EXCEPTION 'Invalid dependency_type: %. Valid values are: blocks, relates_to, duplicates, predecessor_of, successor_of', p_dependency_type;
    END IF;
END;
$$;

-- Teams
-- Хранимая процедура для создания новой команды
CREATE OR REPLACE PROCEDURE create_team(
    p_team_name VARCHAR(128),
    p_owner_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO teams (name, owner_id)
    VALUES (p_team_name, p_owner_id);
END;
$$;

-- Хранимая процедура для добавления участника в команду
CREATE OR REPLACE PROCEDURE add_team_member(
    p_team_name VARCHAR(128),
    p_user_name VARCHAR(128),
    p_role VARCHAR(32) DEFAULT 'member'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_valid_roles TEXT[] := ARRAY['lead', 'developer', 'tester', 'devops', 'manager', 'analyst', 'member'];
BEGIN
    -- Проверяем, что роль является допустимым значением enum
    IF p_role = ANY(v_valid_roles) THEN
        INSERT INTO team_members (team_id, user_id, role)
        VALUES (
            (SELECT id FROM teams WHERE team_name = p_team_name), 
            (SELECT id FROM users WHERE username = p_user_name), 
            p_role::team_role
        );
    ELSE
        RAISE EXCEPTION 'Invalid role: %. Valid values are: lead, developer, tester, devops, manager, analyst, member', p_role;
    END IF;
END;
$$;

-- Time tracking
-- Хранимая процедура для добавления записи о затраченном времени
CREATE OR REPLACE PROCEDURE add_time_entry(
    p_task_id BIGINT,
    p_user_name VARCHAR(128),
    p_entry_date DATE,
    p_hours_spent NUMERIC(5,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO time_entries (task_id, user_id, entry_date, hours_spent)
    VALUES (
        p_task_id,
        (SELECT id FROM users WHERE username = p_user_name),
        p_entry_date,
        p_hours_spent
    );
END;
$$;
