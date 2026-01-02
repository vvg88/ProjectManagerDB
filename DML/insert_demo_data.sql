SET search_path = proj_manager, PUBLIC;

-- Create statuses
INSERT INTO statuses (status) VALUES
  ('planned'),
  ('active'),
  ('completed'),
  ('on_hold'),
  ('cancelled')
ON CONFLICT (status) DO NOTHING;

-- Create priorities
INSERT INTO priorities (priority_level, color_code) VALUES
  ('low', '#00FF00'),
  ('normal', '#FFFF00'),
  ('high', '#FFA500'),
  ('urgent', '#FF0000')

-- Create demo users. DO NOT USE md5 in production; this is just for demo purposes.
INSERT INTO users (username, email, password_hash) VALUES
  ('alice', 'alice@example.com', md5('demo_hash_alice')),
  ('bob', 'bob@example.com', md5('demo_hash_bob')),
  ('carol', 'carol@example.com', md5('demo_hash_carol')),
  ('dave', 'dave@example.com', md5('demo_hash_dave')),
  ('eve', 'eve@example.com', md5('demo_hash_eve')),
  ('frank', 'frank@example.com', md5('demo_hash_frank')),
  ('grace', 'grace@example.com', md5('demo_hash_grace')),
  ('heidi', 'heidi@example.com', md5('demo_hash_heidi')),
  ('ivan', 'ivan@example.com', md5('demo_hash_ivan')),
  ('john', 'john@example.com', md5('demo_hash_john')),
  ('max', 'max@example.com', md5('demo_hash_max'))

ON CONFLICT (username) DO NOTHING;

-- Insert demo projects
INSERT INTO projects (name, description, start_date, end_date, status_id, owner_id) VALUES
  ('Frontend App', 'Develop frontend application', '2025-12-01', '2025-07-30',
    (SELECT id FROM statuses WHERE status = 'active'),
    (SELECT id FROM users WHERE username = 'bob')),
  ('Mobile App', 'Develop mobile app for iOS and Android', '2026-02-01', '2026-09-30',
    (SELECT id FROM statuses WHERE status = 'planned'),
    (SELECT id FROM users WHERE username = 'bob')),
  ('Data Migration', 'Migrate data to new warehouse', '2025-06-01', '2025-11-30',
    (SELECT id FROM statuses WHERE status = 'completed'),
    (SELECT id FROM users WHERE username = 'carol')),
  ('Backend App', 'Develop backend services for API', '2025-12-01', '2026-06-30',
    (SELECT id FROM statuses WHERE status = 'active'),
    (SELECT id FROM users WHERE username = 'carol')),
  ('Security Audit', 'Third-party security audit of systems', '2025-09-15', '2025-10-15',
    (SELECT id FROM statuses WHERE status = 'completed'),
    (SELECT id FROM users WHERE username = 'alice')),
  ('Marketing Campaign', 'Q2 marketing push for new product', '2026-01-12', '2026-02-28',
    (SELECT id FROM statuses WHERE status = 'on_hold'),
    (SELECT id FROM users WHERE username = 'alice'));

-- Create demo teams
INSERT INTO teams (team_name, owner_id) VALUES
  ('Marketing', (SELECT id FROM users WHERE username = 'alice')),
  ('Frontend', (SELECT id FROM users WHERE username = 'bob')),
  ('Backend', (SELECT id FROM users WHERE username = 'carol'))

INSERT INTO team_members (team_id, user_id, role) VALUES
  ((SELECT id FROM teams WHERE team_name = 'Marketing'), (SELECT id FROM users WHERE username = 'alice'), 'lead'),
  ((SELECT id FROM teams WHERE team_name = 'Marketing'), (SELECT id FROM users WHERE username = 'dave'), 'analyst'),
  ((SELECT id FROM teams WHERE team_name = 'Marketing'), (SELECT id FROM users WHERE username = 'eve'), 'member'),
  ((SELECT id FROM teams WHERE team_name = 'Frontend'), (SELECT id FROM users WHERE username = 'bob'), 'lead'),
  ((SELECT id FROM teams WHERE team_name = 'Frontend'), (SELECT id FROM users WHERE username = 'frank'), 'developer'),
  ((SELECT id FROM teams WHERE team_name = 'Frontend'), (SELECT id FROM users WHERE username = 'grace'), 'developer'),
  ((SELECT id FROM teams WHERE team_name = 'Frontend'), (SELECT id FROM users WHERE username = 'heidi'), 'tester'),
  ((SELECT id FROM teams WHERE team_name = 'Backend'), (SELECT id FROM users WHERE username = 'carol'), 'lead'),
  ((SELECT id FROM teams WHERE team_name = 'Backend'), (SELECT id FROM users WHERE username = 'ivan'), 'developer'),
  ((SELECT id FROM teams WHERE team_name = 'Backend'), (SELECT id FROM users WHERE username = 'john'), 'developer'),
  ((SELECT id FROM teams WHERE team_name = 'Backend'), (SELECT id FROM users WHERE username = 'max'), 'devops')

INSERT INTO tasks (name, description, due_date, status_id, project_id, assigned_to)
SELECT
  'Design UI components',
  'Create and document core UI components and design system.',
  '2026-01-15',
  (SELECT id FROM statuses WHERE status = 'active' LIMIT 1),
  (SELECT id FROM projects WHERE name = 'Frontend App' LIMIT 1),
  (SELECT id FROM users WHERE username = 'frank' LIMIT 1)

INSERT INTO tasks (name, description, due_date, status_id, project_id, assigned_to)
SELECT
  'Decompose december features',
  'Break down December roadmap features into smaller tasks, estimate effort and assign owners.',
  '2025-12-15',
  (SELECT id FROM statuses WHERE status = 'completed' LIMIT 1),
  (SELECT id FROM projects WHERE name = 'Frontend App' LIMIT 1),
  (SELECT id FROM users WHERE username = 'bob' LIMIT 1)

  -- To be continued
