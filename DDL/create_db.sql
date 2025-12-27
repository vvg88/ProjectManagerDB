CREATE DATABASE project_manager_db;

CREATE SCHEMA IF NOT EXISTS proj_manager;

# Create an admin user
CREATE USER pm_admin WITH PASSWORD '!SecurePass123';
GRANT ALL PRIVILEGES ON DATABASE project_manager_db TO pm_admin;

# Create roles and grant privileges
CREATE ROLE dev;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA proj_manager TO dev;
CREATE ROLE analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA proj_manager TO analyst;

# Create example users and assign roles
CREATE USER developer;
GRANT dev TO developer;
CREATE USER analyst_user;
GRANT analyst TO analyst_user;
