# MySQL Project manager DB
В базе данных MySQL используются те же таблицы, что и в PostgreSQL. Основные отличия следующие:
1. Enum-ы объявляются при создании поля таблицы.
1. Для полей 'id' выбран тип `Serial`.
1. Для полей с типом `TIMESTAMP` значение по умолчанию получается с помощью `CURRENT_TIMESTAMP`.
1. Изменения для задачи в таблице `log_history` хранятся в формате JSON со следующей структурой:
```json
{
   "status": "In Progress",
   "name": "Implement login feature",
   "description": "Implement user authentication and authorization",
   "assigned_to": 123,
   "due_date": "2024-12-31",
   "priority_id": 2
}
```