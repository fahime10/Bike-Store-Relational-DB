-- Shipping performance analysis

USE BikeStoreDB;

SELECT * FROM orders;

-- Average order processing time per store
SELECT 
	st.store_name, 
	AVG(DATEDIFF(DAY, o.order_date, o.shipped_date)) AS days_taken_to_process
FROM orders o
JOIN stores st ON st.store_id = o.store_id
GROUP BY st.store_name;


-- Find out if there are any late processing
SELECT 
	st.store_name, 
	COUNT(o.order_id) AS total_orders,
	SUM(CASE 
			WHEN o.order_status = 4 AND o.shipped_date <= o.required_date THEN 1
			ELSE 0 END) AS orders_completed,
	SUM(CASE
			WHEN o.order_status = 4 AND o.shipped_date > o.required_date THEN 1
			ELSE 0 END) AS late_completed_orders,
	SUM(CASE
			WHEN o.order_status IN (1, 2) AND o.required_date < '2026-04-25' THEN 1
			ELSE 0 END) AS overdue_still_processing
INTO shipping_performance_snapshot
FROM orders o
JOIN stores st ON st.store_id = o.store_id
GROUP BY st.store_name;

SELECT 
	store_name,
	ROUND(CAST(orders_completed * 100.0 AS FLOAT) / NULLIF((orders_completed + late_completed_orders + overdue_still_processing), 0), 2) AS on_time_rate,
	ROUND(CAST((late_completed_orders + overdue_still_processing) * 100.0 AS FLOAT) / NULLIF((orders_completed + late_completed_orders + overdue_still_processing), 0), 2) AS failure_rate
FROM shipping_performance_snapshot
ORDER BY failure_rate;


-- Are there any particular products that could possibly cause the delay?
SELECT
	st.store_name,
	b.brand_name,
	COUNT(oi.order_id) AS total_orders,
	SUM(CASE
			WHEN o.shipped_date > o.required_date OR (o.order_status IN (1, 2) AND o.required_date < '2026-04-25') THEN 1 
			ELSE 0 END) AS delayed_items,
	ROUND(CAST(SUM(CASE
				WHEN o.shipped_date > o.required_date OR (o.order_status IN (1, 2) AND o.required_date < '2026-04-25') THEN 1
				ELSE 0 END) AS FLOAT) * 100.0 / COUNT(oi.order_id), 2) AS brand_late_rate
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN stores st ON st.store_id = o.store_id
JOIN products p ON oi.product_id = p.product_id
JOIN brands b ON p.brand_id = b.brand_id
GROUP BY st.store_name, b.brand_name
HAVING COUNT(oi.order_id) > 5
ORDER BY st.store_name, brand_late_rate DESC;