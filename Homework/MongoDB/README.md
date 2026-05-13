# Mongo DB
## MongoDB Docker контейнер
Получить `mongo` образ и запустить контейнер:

![mongo_pull](./pics/mongo_pull.png)

Запустить контейнер и войти в mongosh:

![mongo-sh](./pics/mongo-sh.png)

## Заполнение данными
Заполнить MongoDB демонстрационными данными. Создаются коллекции `users`, `projects`, `tasks` и наполняются данными.

![insert-demo-data](./pics/insert-demo-data.png)

## Выборка данных
Получить всех пользователей:

![all-users](./pics/all-users.png)

Задача пользователя `bob`:

![bob-task](./pics/bobs-task.png)

Найти проект, не принадлежащий пользователю `bob` и пропустить 1:

![nobob-project](./pics/alices-project.png)

Найти задачу, принадлежащую проекту, чьё название начинвется на `Data`и не выводить поля `_id` и `descroption`:

![data-tasks](./pics/data-tasks.png)

## Изменение данных:
Назначить задачу пользователя `bob` на `alice`:

![update-task](./pics/mongo-update.png)

Добавить проектам новое поле `estimatedHoursSpent`:

![set-field](./pics/set-field.png)

Удалить задачу, назначенную `carol`:

![delete-task](./pics/delete-task.png)

Удалить коллекцию задач:

![drop-tasks](./pics/drop-tasks.png)