# PostgreSQL Docker container

База данных запускается в контейнере Docker. Для этого необходимо сделать следующее:
Скачать образ postgres:
![load_image](/Docs/PostgreSQL%20container/pics/Download_container.png)
Запустить контейнер:
![run_container](/Docs/PostgreSQL%20container/pics/Run_container.png)
Подключить клиент DBeaver:
![connect_db](/Docs/PostgreSQL%20container/pics/Connect_db.png)
Создать тестовую таблицу test_table, выполнив скрипт 
```
create table test_table(id int, description text)
```
Удостовериться, что таблица создана:

<img src="/Docs/PostgreSQL%20container/pics/Create_table.png" alt="create_table" width="640">

Добавить данные в таблицу и прочитать их:
```
insert into test_table values (0, 'text'), (1, 'test text'), (2, 'test data');
select * from test_table;
```
![read_data](/Docs/PostgreSQL%20container/pics/Read_data.png)
