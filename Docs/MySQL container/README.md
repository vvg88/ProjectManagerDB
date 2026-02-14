# MySQL Docker container

База данных запускается в контейнере Docker. Для этого необходимо сделать следующее:

Скачать образ mysql:

![mysql_image](./pics/mysql_image.png)

Запустить контейнер:

![mysql_run_container.sql](./pics/mysql_run_container.png)

Подключить клиент:

![client_connect](./pics/client_connect.png)

Создать базу данных `project_manager_db` с помощью команд:
```sql
CREATE DATABASE project_manager_db;
USE project_manager_db;
```
![create_db](./pics/create_db.png)

Создать таблицу `test_table`:
```sql
CREATE TABLE test_table(id INT, description VARCHAR(255));
```

![create_table](./pics/create_table.png)

Наполнить её данными и прочитать их:
```sql
INSERT INTO test_table VALUES (0, 'text'), (1, 'test text'), (2, 'test data');
SELECT * FROM test_table;
```
![insert_data](./pics/insert_data.png)