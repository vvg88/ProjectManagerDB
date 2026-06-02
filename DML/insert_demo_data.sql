SET search_path = proj_manager, PUBLIC;

-- Statuses
INSERT INTO statuses (status) VALUES
  ('planned'),
  ('active'),
  ('completed'),
  ('on_hold'),
  ('cancelled')
ON CONFLICT (status) DO NOTHING;

-- Priorities
INSERT INTO priorities (priority_level) VALUES
  ('low'),
  ('normal'),
  ('high'),
  ('urgent')
ON CONFLICT (priority_level) DO NOTHING;

-- Создать пользователей с хэшами паролей для демонстрационных целей
INSERT INTO users (username, email, password_hash) VALUES
  ('Bob', 'bob@example.com', md5('demo_hash_bob')),
  ('Carol', 'carol@example.com', md5('demo_hash_carol')),
  ('Frank', 'frank@example.com', md5('demo_hash_frank')),
  ('Grace', 'grace@example.com', md5('demo_hash_grace')),
  ('Heidi', 'heidi@example.com', md5('demo_hash_heidi')),
  ('Ivan', 'ivan@example.com', md5('demo_hash_ivan')),
  ('John', 'john@example.com', md5('demo_hash_john')),
  ('Max', 'max@example.com', md5('demo_hash_max'))
ON CONFLICT (username) DO NOTHING;

DO $$
DECLARE
  v_error_code INT;
BEGIN
  -- Вставить демонстрационные проекты с использованием хранимых процедур
  CALL create_project(
    'Frontend App',
    'Разработка фронтенд-приложения',
    '2026-01-15',
    '2026-08-31',
    'active',
    'Bob',
    v_error_code
  );

  CALL create_project(
    'Backend App',
    'Разработка бэкенд-сервисов для API',
    '2026-02-01',
    '2026-09-15',
    'active',
    'Carol',
    v_error_code
  );
END $$;

DO $$
DECLARE
  v_error_code INT;
BEGIN  
  -- Добавить команды с помощью хранимых процедур
  CALL create_team(
    'Frontend Team',
    'Bob',
    v_error_code
  );

  CALL create_team(
    'Backend Team',
    'Carol',
    v_error_code
  );

  -- Добавить членов команды с использованием хранимых процедур
  CALL add_team_member('Frontend Team', 'Bob', v_error_code, 'lead');
  CALL add_team_member('Frontend Team', 'Frank', v_error_code, 'developer');
  CALL add_team_member('Frontend Team', 'Grace', v_error_code, 'developer');
  CALL add_team_member('Frontend Team', 'Heidi', v_error_code, 'tester');
  CALL add_team_member('Backend Team', 'Carol', v_error_code, 'lead');
  CALL add_team_member('Backend Team', 'Ivan', v_error_code, 'developer');
  CALL add_team_member('Backend Team', 'John', v_error_code, 'developer');
  CALL add_team_member('Backend Team', 'Max', v_error_code, 'devops');
END $$;

-- Вставить демонстрационные задачи с использованием хранимых процедур
DO $$
DECLARE
  v_error_code INT;
  v_frontend_project_id BIGINT;
  v_backend_project_id BIGINT;
BEGIN
  -- Сохранять ID проектов в переменные для использования при создании задач
  SELECT id INTO v_frontend_project_id FROM projects WHERE name = 'Frontend App' LIMIT 1;
  SELECT id INTO v_backend_project_id FROM projects WHERE name = 'Backend App' LIMIT 1;

  CALL create_task(
    'Разработка UI компонентов',
    'Создать основные UI компоненты для фронтенд-приложения, включая кнопки, формы и навигацию.',
    '2026-05-20',
    'active',
    'high',
    v_frontend_project_id,
    v_error_code,
    'Frank'
  );

  CALL create_task(
    'Реализация UI аутентификации',
    'Создать интерфейсы входа и регистрации пользователей с использованием лучших практик безопасности.',
    '2026-05-25',
    'active',
    'high',
    v_frontend_project_id,
    v_error_code,
    'Grace'
  );

  CALL create_task(
    'Настройка backend API',
    'Разработать и развернуть RESTful API для управления данными приложения.',
    '2026-05-15',
    'active',
    'urgent',
    v_backend_project_id,
    v_error_code,
    'Carol'
  );

  CALL create_task(
    'Дизайн базы данных',
    'Создать и оптимизировать схему базы данных для бэкенд-сервисов.',
    '2026-05-20',
    'active',
    'high',
    v_backend_project_id,
    v_error_code,
    'Ivan'
  );

  CALL create_task(
    'Документация API endpoint',
    'Создать подробную документацию для всех API endpoint.',
    '2026-05-22',
    'active',
    'normal',
    v_backend_project_id,
    v_error_code,
    'John'
  );
END $$;

DO $$
DECLARE
  v_error_code INT;
  v_task_ui_comp_id BIGINT;
  v_task_ui_auth_id BIGINT;
  v_task_api_setup_id BIGINT;
  v_task_db_design_id BIGINT;
  v_task_api_doc_id BIGINT;
BEGIN
  -- Получить ID задач для добавления комментариев
  SELECT id INTO v_task_ui_comp_id FROM tasks WHERE name = 'Разработка UI компонентов' LIMIT 1;
  SELECT id INTO v_task_ui_auth_id FROM tasks WHERE name = 'Реализация UI аутентификации' LIMIT 1;
  SELECT id INTO v_task_api_setup_id FROM tasks WHERE name = 'Настройка backend API' LIMIT 1;
  SELECT id INTO v_task_db_design_id FROM tasks WHERE name = 'Дизайн базы данных' LIMIT 1;
  SELECT id INTO v_task_api_doc_id FROM tasks WHERE name = 'Документация API endpoint' LIMIT 1;

-- Добавить комментарии к задачам с использованием хранимых процедур
  CALL add_comment_to_task(
    v_task_ui_comp_id,
    'Bob',
    'Убедиться, что дизайн соответствует гайдлайнам компании. Использовать цветовую палитру из дизайн-системы.',
    v_error_code
  );

  CALL add_comment_to_task(
    v_task_ui_auth_id,
    'Heidi',
    'Компоненты выглядят хорошо. Готовы к тестированию после завершения разработки.',
    v_error_code
  );

  CALL add_comment_to_task(
    v_task_api_setup_id,
    'Carol',
    'Необходимо уточнить стратегию аутентификации API перед реализацией.',
    v_error_code
  );

  CALL add_comment_to_task(
    v_task_api_setup_id,
    'Max',
    'Настройка инфраструктуры в процессе. Docker контейнеры готовы.',
    v_error_code
  );

  CALL add_comment_to_task(
    v_task_ui_auth_id,
    'Bob',
    'Координировать с бэкендом для получения деталей реализации OAuth2.',
    v_error_code
  );

  -- Добавить записи времени
  CALL add_time_entry(v_task_ui_comp_id, 'Frank', '2026-05-20', 4.5, v_error_code);
  CALL add_time_entry(v_task_ui_auth_id, 'Frank', '2026-05-21', 3.0, v_error_code);
  CALL add_time_entry(v_task_ui_comp_id, 'Frank', '2026-05-24', 4.0, v_error_code);
  CALL add_time_entry(v_task_ui_auth_id, 'Grace', '2026-05-25', 5.5, v_error_code);
  CALL add_time_entry(v_task_db_design_id, 'Ivan', '2026-05-20', 5.5, v_error_code);
  CALL add_time_entry(v_task_db_design_id, 'Ivan', '2026-05-21', 4.0, v_error_code);
  CALL add_time_entry(v_task_api_setup_id, 'Carol', '2026-05-15', 6.0, v_error_code);
  CALL add_time_entry(v_task_api_setup_id, 'Carol', '2026-05-16', 5.0, v_error_code);
  CALL add_time_entry(v_task_api_doc_id, 'John', '2026-05-22', 3.5, v_error_code);

  -- Добавить зависимости между задачами
  CALL set_task_dependency(v_task_api_setup_id, v_task_db_design_id, 'successor_of', v_error_code);
  CALL set_task_dependency(v_task_api_doc_id, v_task_api_setup_id, 'successor_of', v_error_code);

  -- Добавить файлы к задачам
  CALL add_file_to_task(v_task_ui_comp_id, 'ui-components-guide.pdf', '/uploads/ui-components-guide.pdf', 'pdf', v_error_code);
  CALL add_file_to_task(v_task_ui_comp_id, 'design-system.pdf', '/uploads/design-system.pdf', 'pdf', v_error_code);
  CALL add_file_to_task(v_task_db_design_id, 'schema-design.doc', '/uploads/schema-design.doc', 'doc', v_error_code);
  CALL add_file_to_task(v_task_db_design_id, 'ER-diagram.zip', '/uploads/ER-diagram.zip', 'zip', v_error_code);
  CALL add_file_to_task(v_task_api_doc_id, 'endpoints.doc', '/uploads/endpoints.doc', 'doc', v_error_code);
  CALL add_file_to_task(v_task_api_setup_id, 'endpoints.doc', '/uploads/endpoints.doc', 'doc', v_error_code);
END $$;