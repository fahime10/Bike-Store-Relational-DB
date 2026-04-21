-- Identify which products customers want to buy but cannot find 

-- The database does not have a table to provide that answer straight away
-- so it needs to be inferred. Therefore, look for products that have a 
-- high historical sales velocity, and those currently have zero or near-zero
-- quantity in stocks table

USE BikeStoreDB;

SELECT p.product_id, p.product_name, p.list_price,
	   COALESCE(SUM(CAST(oi.quantity AS INT)), 0) AS total_units_sold,
	   COALESCE(ROUND(SUM(CAST(oi.quantity AS INT) * oi.list_price * (1 - oi.discount)), 2), 0) AS total_revenue
INTO historical_revenue_snapshot
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.list_price
ORDER BY total_units_sold DESC;

SELECT * FROM historical_revenue_snapshot;

SELECT * FROM historical_revenue_snapshot
ORDER BY total_revenue DESC;


WITH ProductDemand AS (
	SELECT o.store_id, oi.product_id, SUM(CAST(oi.quantity AS INT)) AS units_sold_all_time
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	GROUP BY o.store_id, oi.product_id
)
SELECT st.store_id, p.product_name, pd.units_sold_all_time, 
	   st.quantity AS current_stock_level,
	   (pd.units_sold_all_time * p.list_price) AS historical_value_$
FROM products p
JOIN ProductDemand pd ON p.product_id = pd.product_id
JOIN stocks st ON p.product_id = st.product_id AND pd.store_id = st.store_id
WHERE st.quantity = 0 
ORDER BY pd.units_sold_all_time DESC;


WITH ProductDemand AS (
	SELECT o.store_id, oi.product_id, SUM(CAST(oi.quantity AS INT)) AS units_sold_all_time
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	GROUP BY o.store_id, oi.product_id
)
SELECT st.store_id, p.product_name, pd.units_sold_all_time, 
	   st.quantity AS current_stock_level,
	   (pd.units_sold_all_time * p.list_price) AS historical_revenue_$
INTO latent_demand_snapshot
FROM products p
JOIN ProductDemand pd ON p.product_id = pd.product_id
JOIN stocks st ON p.product_id = st.product_id AND pd.store_id = st.store_id
WHERE st.quantity = 0 
ORDER BY pd.units_sold_all_time DESC;

SELECT * FROM latent_demand_snapshot;

SELECT * FROM latent_demand_snapshot
ORDER BY historical_revenue_$ DESC;