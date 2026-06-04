SET search_path = proj_manager, PUBLIC;

-- Встаить 10000 записей в таблицу time_tracking для тестирования производительности запросов
DO $$
DECLARE  
  v_task_id INT;
  v_user_id INT;
  v_hours_spent NUMERIC;
  v_entry_date DATE;
BEGIN
  FOR i IN 1..10000 LOOP
    v_task_id := (RANDOM() * 100)::INT + 1; -- Случайный task_id from 1..100
    v_user_id := (RANDOM() * 20)::INT + 1; -- Случайный user_id from 1..20
    v_hours_spent := (RANDOM() * 8)::NUMERIC; -- Случайное количество часов от 0 до 8
    v_entry_date := '2026-01-01'::DATE + (RANDOM() * 365)::INT; -- Случайная дата from 2026-01-01 to 2026-12-31
    
    INSERT INTO time_tracking(task_id, user_id, entry_date, hours_spent)
    VALUES (v_task_id, v_user_id, v_entry_date, v_hours_spent);
  END LOOP;
END $$;

-- Выполнить запрос для анализа производительности до создания индекса
EXPLAIN ANALYZE SELECT
       tt.user_id,
       tt.entry_date,
       SUM(tt.hours_spent) AS total_hours
FROM proj_manager.time_tracking tt
WHERE tt.task_id = 10
GROUP BY tt.user_id, tt.entry_date
ORDER BY tt.entry_date DESC;

/* Результат выполнения запроса до создания индекса:
 GroupAggregate  (cost=212.40..214.64 rows=97 width=44) (actual time=0.390..0.422 rows=102.00 loops=1)
   Group Key: entry_date, user_id
   Buffers: shared hit=84
   ->  Sort  (cost=212.40..212.66 rows=102 width=18) (actual time=0.380..0.384 rows=102.00 loops=1)
         Sort Key: entry_date DESC, user_id
         Sort Method: quicksort  Memory: 28kB
         Buffers: shared hit=84
         ->  Seq Scan on time_tracking tt  (cost=0.00..209.00 rows=102 width=18) (actual time=0.009..0.353 rows=102.00 loops=1)
               Filter: (task_id = 10)
               Rows Removed by Filter: 9898
               Buffers: shared hit=84
 Planning:
   Buffers: shared hit=32
 Planning Time: 0.308 ms
 Execution Time: 0.455 ms
*/

-- Создать индекс для оптимизации запроса
CREATE INDEX idx_time_tracking_task_id_user_id ON time_tracking(task_id, user_id) INCLUDE (hours_spent, entry_date);

/* Результат выполнения запроса после создания индекса:
 Sort  (cost=11.25..11.49 rows=97 width=44) (actual time=0.190..0.197 rows=102.00 loops=1)
   Sort Key: entry_date DESC
   Sort Method: quicksort  Memory: 28kB
   Buffers: shared hit=1 read=3
   ->  HashAggregate  (cost=6.83..8.05 rows=97 width=44) (actual time=0.129..0.165 rows=102.00 loops=1)
         Group Key: entry_date, user_id
         Batches: 1  Memory Usage: 56kB
         Buffers: shared hit=1 read=3
         ->  Index Only Scan using idx_time_tracking_task_id_user_id on time_tracking tt  (cost=0.29..6.07 rows=102 width=18) (actual time=0.033..0.068 rows=102.00 loops=1)
               Index Cond: (task_id = 10)
               Heap Fetches: 0
               Index Searches: 1
               Buffers: shared hit=1 read=3
 Planning:
   Buffers: shared hit=27 read=1
 Planning Time: 0.381 ms
 Execution Time: 0.262 ms
*/

/*****************************************************************
 Заключение: Создание индекса улучшило производительность запроса,
 снизив время выполнения с 0.455 ms до 0.262 ms.

 В запросе до создания индекса, PostgreSQL выполнял последовательное
 сканирование всей таблицы time_tracking - Seq Scan on time_tracking tt.

 После создания индекса, PostgreSQL использовал Index Only Scan
 Index Only Scan using idx_time_tracking_task_id_user_id on time_tracking tt.
 Это ускорило фильтрацию по task_id и позволило избежать чтения из кучи,
 так как все необходимые данные были доступны в индексе.
*****************************************************************/