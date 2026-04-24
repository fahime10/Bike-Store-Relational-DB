-- Customer Rentention Analysis

USE BikeStoreDB;

-- Find repeat customers
SELECT customer_id, COUNT(*) AS total_purchases
FROM orders
GROUP BY customer_id
ORDER BY total_purchases DESC;

-- Create buckets (segmentation)
WITH CustomerTraffic AS (
	SELECT customer_id, store_id, COUNT(order_id) as order_count
	FROM orders
	GROUP BY customer_id, store_id
)
SELECT store_id, customer_id, order_count,
CASE 
	WHEN order_count > 1 THEN 'Loyal'
	ELSE 'One-Time'
END AS loyalty_status
INTO loyalty_snapshot
FROM CustomerTraffic
ORDER BY order_count DESC;

-- Find customer retention per store
SELECT 
	st.store_name, 
	ls.loyalty_status, 
	COUNT(*) AS status_count,
	SUM(COUNT(*)) OVER(PARTITION BY ls.store_id) AS total_store_customers,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY ls.store_id) * 100, 2) AS loyalty_percentage
INTO customer_retention
FROM loyalty_snapshot ls
JOIN stores st ON ls.store_id = st.store_id
GROUP BY st.store_name, ls.loyalty_status, ls.store_id;

SELECT * FROM customer_retention;

-- Baldwin has a higher percentage of one-time customers (94.11%), which could indicate that they do not have a good customer 
-- retention method in place, however, it is still leading in terms of volume of customers.
-- Rowlett has slightly more customers that have purchased more one product (13.38 % vs Baldwin's 5.89%).
-- Santa Cruz has the highest loyal customer base (18.18%), however, its volume is rather low compared to Baldwin (286 total 
-- customers against Baldwin's 1,019 total customers).


-- Customer loyalty buckets can be further segmented
WITH CustomerTrafficAdvanced AS (
	SELECT customer_id, store_id, COUNT(order_id) AS order_count
	FROM orders
	GROUP BY customer_id, store_id
)
SELECT store_id, customer_id, order_count,
CASE
	WHEN order_count >= 3 THEN 'Fan'
	WHEN order_count > 1 THEN 'Loyal'
	ELSE 'One-Time'
END AS loyalty_status
INTO loyalty_advanced_snapshot
FROM CustomerTrafficAdvanced;

SELECT * FROM loyalty_advanced_snapshot
ORDER BY order_count DESC;

SELECT 
	st.store_name, 
	ls.loyalty_status,
	COUNT(*) AS status_count,
	SUM(COUNT(*)) OVER(PARTITION BY ls.loyalty_status) AS total_store_customers,
	ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER(PARTITION BY ls.store_id) * 100, 2) AS status_percentage
INTO customer_retention_advanced
FROM loyalty_advanced_snapshot ls
JOIN stores st ON st.store_id = ls.store_id
GROUP BY st.store_name, ls.loyalty_status, ls.store_id;

SELECT * 
FROM customer_retention_advanced
ORDER BY loyalty_status;