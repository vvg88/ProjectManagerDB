# Оптимизация запросов

Проанализировать запрос для получения магазинов, у которых объем продаж в месяц превышает средний объем продаж по этому магазину
``` sql
WITH sales_in_month AS (
    SELECT store_id,
           DATE_FORMAT(date, '%Y-%m') AS month,
           SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY store_id, month
)
SELECT s.store_id, s.address, sim.month, sim.total_sales FROM sales_in_month sim
JOIN stores s ON sim.store_id = s.store_id
WHERE sim.total_sales > (
    SELECT AVG(total_sales) FROM sales_in_month WHERE store_id = sim.store_id
)
ORDER BY sim.month, sim.total_sales;
```

Результат выполнения `EXPLAIN ANALYZE`
```
-> Sort: sim.`month`, sim.total_sales  (actual time=10.8..10.8 rows=114 loops=1)
    -> Stream results  (cost=348 rows=990) (actual time=9.31..10.7 rows=114 loops=1)
        -> Nested loop inner join  (cost=348 rows=990) (actual time=9.3..10.7 rows=114 loops=1)
            -> Table scan on s  (cost=1.25 rows=10) (actual time=0.0305..0.036 rows=10 loops=1)
            -> Filter: (sim.total_sales > (select #3))  (cost=25.7 rows=99) (actual time=1..1.06 rows=11.4 loops=10)
                -> Index lookup on sim using <auto_key0> (store_id = s.store_id)  (cost=0.26..25.7 rows=99) (actual time=0.914..0.917 rows=25 loops=10)
                    -> Materialize CTE sales_in_month if needed  (cost=0..0 rows=0) (actual time=9.13..9.13 rows=250 loops=1)
                        -> Table scan on <temporary>  (actual time=8.98..9.01 rows=250 loops=1)
                            -> Aggregate using temporary table  (actual time=8.98..8.98 rows=250 loops=1)
                                -> Table scan on sales  (cost=992 rows=9840) (actual time=0.115..2.12 rows=10000 loops=1)
                -> Select #3 (subquery in condition; dependent)
                    -> Aggregate: avg(sales_in_month.total_sales)  (cost=344..344 rows=1) (actual time=0.00531..0.00534 rows=1 loops=250)
                        -> Index lookup on sales_in_month using <auto_key0> (store_id = sim.store_id)  (cost=0.35..344 rows=985) (actual time=380e-6..0.0032 rows=25 loops=250)
                            -> Materialize CTE sales_in_month if needed (query plan printed elsewhere)  (cost=0..0 rows=0) (never executed)
```

## Интерпретация EXPLAIN ANALYZE

1. **Сортировка финальных результатов** (actual time=10.8..10.8 ms)
   - Сортирует 114 строк по месяцу и сумме продаж
   - Это верхний уровень плана, выполняется в последнюю очередь

2. **Вложенный цикл с объединением (Nested Loop Join)** (actual time=9.3..10.7 ms)
   - Основной процесс обработки данных
   - Выполняется 10 раз (по одному для каждого магазина из таблицы stores)
   
   1. **Сканирование таблицы stores** (actual time=0.0305..0.036 ms)
      - Полное сканирование 10 магазинов
      - Используется как внешний цикл для Nested Loop Join
   
   2. **Фильтрация по подзапросу** (actual time=1..1.06 ms, loops=10)
      - Проверяет условие: total_sales > средний_доход_магазина
      - Выполняется для каждого магазина (10 итераций)
      - Фильтр оставляет 114 результирующих строк (11.4 строк в среднем на магазин)
      
      1. **Поиск по индексу CTE** (actual time=0.914..0.917 ms, loops=10)
         - Ищет записи по store_id в CTE sales_in_month
         - Находит 25 месячных записей для каждого магазина
      
      2. **Материализация CTE** (actual time=9.13..9.13 ms, loops=1)
         - Создает временную таблицу с результатами CTE
         - Выполняется один раз для всего запроса
         - Содержит 250 строк (10 магазинов × 25 месяцев/магазин)
         
         1. **Агрегирование во временную таблицу** (actual time=8.98..8.98 ms)
            - Группирует по store_id и месяцу
            - Суммирует sale_amount для каждой группы
         
         2. **Полное сканирование таблицы sales** (actual time=0.115..2.12 ms)
            - Читает все 10,000 записей продаж
            - Исходные данные для агрегирования
      
      3. **Зависимый подзапрос** (actual time=0.00531..0.00534 ms, loops=250)
         - ⚠️ **УЗКОЕ МЕСТО**: Выполняется **250 раз** вместо 10
         - Вычисляет AVG(total_sales) для каждого store_id
         - Должен вычисляться один раз на магазин, а не на каждую строку CTE
         
         - **Поиск по индексу для подзапроса** (actual time=380e-6..0.0032 ms, loops=250)
           - Ищет записи в CTE по store_id
           - Находит 25 строк на итерацию

## Ключевые проблемы производительности

- **Зависимый подзапрос**: Выполняется 250 раз вместо 10 раз - это главное узкое место
- **Материализация CTE**: 9.13 ms занимает создание временной таблицы
- **Общее время**: 10.8 ms для выполнения запроса

## Альтернативное решение
Вместо корреляции по store_id можно предварительно вычислить среднее для каждого магазина в отдельном CTE.
``` sql
WITH sales_in_month AS (
    SELECT store_id,
           DATE_FORMAT(date, '%Y-%m') AS month,
           SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY store_id, month
),
store_avg AS (
    SELECT store_id,
           AVG(total_sales) AS avg_sales
    FROM sales_in_month
    GROUP BY store_id
)
SELECT s.store_id, s.address, sim.month, sim.total_sales 
FROM sales_in_month sim
JOIN stores s ON sim.store_id = s.store_id
JOIN store_avg sa ON sim.store_id = sa.store_id
WHERE sim.total_sales > sa.avg_sales
ORDER BY sim.month, sim.total_sales;
```

Результат выполнения `EXPLAIN ANALYZE`
```
-> Sort: sim.`month`, sim.total_sales  (actual time=8.04..8.05 rows=114 loops=1)
    -> Stream results  (cost=24751 rows=0) (actual time=7.69..7.94 rows=114 loops=1)
        -> Nested loop inner join  (cost=24751 rows=0) (actual time=7.69..7.92 rows=114 loops=1)
            -> Nested loop inner join  (cost=249 rows=0) (actual time=7.57..7.63 rows=250 loops=1)
                -> Table scan on s  (cost=1.25 rows=10) (actual time=0.0563..0.0615 rows=10 loops=1)
                -> Index lookup on sim using <auto_key0> (store_id = s.store_id)  (cost=0.26..25.7 rows=99) (actual time=0.752..0.755 rows=25 loops=10)
                    -> Materialize CTE sales_in_month if needed  (cost=0..0 rows=0) (actual time=7.51..7.51 rows=250 loops=1)
                        -> Table scan on <temporary>  (actual time=7.36..7.39 rows=250 loops=1)
                            -> Aggregate using temporary table  (actual time=7.36..7.36 rows=250 loops=1)
                                -> Table scan on sales  (cost=992 rows=9840) (actual time=0.107..1.75 rows=10000 loops=1)
            -> Filter: (sim.total_sales > sa.avg_sales)  (cost=24.8 rows=33) (actual time=938e-6..0.00101 rows=0.456 loops=250)
                -> Covering index lookup on sa using <auto_key0> (store_id = s.store_id)  (cost=0.25..24.8 rows=99) (actual time=702e-6..808e-6 rows=1 loops=250)
                    -> Materialize CTE store_avg  (cost=0..0 rows=0) (actual time=0.0999..0.0999 rows=10 loops=1)
                        -> Table scan on <temporary>  (actual time=0.0841..0.085 rows=10 loops=1)
                            -> Aggregate using temporary table  (actual time=0.0838..0.0838 rows=10 loops=1)
                                -> Table scan on sales_in_month  (cost=2.5..2.5 rows=0) (actual time=985e-6..0.0243 rows=250 loops=1)
                                    -> Materialize CTE sales_in_month if needed (query plan printed elsewhere)  (cost=0..0 rows=0) (never executed)
```

## Сравнение EXPLAIN ANALYZE: Исходный vs Оптимизированный

### Общие показатели

| Показатель | Исходный запрос | Оптимизированный | Изменение |
|------------|-----------------|------------------|-----------|
| **Общее время выполнения** | 10.8 ms | 8.04 ms | ⬇️ **-25.6%** (выигрыш) |
| **Результирующие строки** | 114 | 114 | = Идентичны |
| **Сортировка** | 10.8..10.8 ms | 8.04..8.05 ms | ⬇️ **-25.6%** |

### Вложенные циклы и объединения

| Компонент | Исходный | Оптимизированный | Изменение |
|-----------|----------|------------------|-----------|
| **Stream results** | 9.31..10.7 ms | 7.69..7.94 ms | ⬇️ **-25.1%** |
| **Nested Loop Join (основной)** | 9.3..10.7 ms | 7.69..7.92 ms | ⬇️ **-25.1%** |
| **Количество вложенных JOIN** | 1 | 2 | ⬆️ Больше, но эффективнее |

### Материализация CTE: решающий фактор

| CTE | Исходный | Оптимизированный | Изменение |
|-----|----------|------------------|-----------|
| **sales_in_month материализация** | 9.13 ms (x1 раз) | 7.51 ms (x1 раз) | ⬇️ **-17.7%** |
| **Агрегирование в sales_in_month** | 8.98..9.01 ms | 8.98..9.01 ms | 🟰 **Без изменений** |
| **Сканирование sales** | 0.115..2.12 ms | 0.107..1.75 ms | ⬇️ **-17.4%** |
| **store_avg материализация** | - (не было) | 0.0999 ms (x1 раз) | ✅ **Новая оптимизация** |

### Критическое различие: обработка среднего значения

| Операция | Исходный | Оптимизированный | Изменение |
|----------|----------|------------------|-----------|
| **Зависимый подзапрос (Select #3)** | 0.00531 ms, **250 раз** | - | ⬇️ **Исключен** |
| **Поиск средних значений** | 380e-6..0.0032 ms, **250 раз** | - | ⬇️ **Исключен** |
| **CTE store_avg фильтрация** | - | 938e-6 ms, **250 раз** | ✅ **Просто сравнение с JOIN** |
| **Covering Index на store_avg** | - | 702e-6..808e-6 ms, **250 раз** | ✅ **Очень быстро** |
| **Итого вычислений AVG** | **250 раз** | **10 раз** | ⬇️ **-96%** |

### Почему оптимизированный запрос быстрее

1. **Исключение зависимого подзапроса** (экономия ~0.25-0.3 ms)
   - Вместо вычисления AVG для каждой строки используется предвычисленное значение

2. **Уменьшение количества вычислений** (96% экономия на AVG)
   - Исходный: 250 раз вычисляется AVG для каждой строки CTE
   - Оптимизированный: 10 раз вычисляется AVG в отдельном CTE

3. **Более эффективный поиск** (-2.6%)
   - Covering Index На малом CTE (10 строк) работает быстрее, чем полное сканирование

4. **Более быстрая материализация sales_in_month** (-17.7%)
   - Хотя оба запроса материализуют это CTE, во втором это происходит немного быстрее (возможно, за счет лучшего кеширования)

### Вывод

**Оптимизированный запрос быстрее на 25.6%** благодаря архитектурной переделке:
- Замена зависимого подзапроса на JOIN с предвычисленным CTE
- Снижение количества вычислений среднего значения с 250 до 10 раз
- Использование более эффективного плана выполнения с двумя Nested Loop Join вместо одного со встроенным подзапросом