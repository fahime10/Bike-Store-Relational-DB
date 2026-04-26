-- Sales Performance and Revenue Analysis

USE BikeStoreDB;

SELECT p.product_id, p.product_name, b.brand_name, p.list_price,
	   COALESCE(SUM(CAST(oi.quantity AS INT)), 0) AS total_units_sold,
	   COALESCE(ROUND(SUM(CAST(oi.quantity AS INT) * oi.list_price * (1 - oi.discount)), 2), 0) AS total_revenue
INTO sales_performance_snapshot
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN brands b ON p.brand_id = b.brand_id
GROUP BY p.product_id, p.product_name, p.list_price, b.brand_name;

-- Top 10 most revenue products
SELECT TOP 10 * 
FROM sales_performance_snapshot
ORDER BY total_revenue DESC;

-- Top 10 least revenue products
SELECT TOP 10 *
FROM sales_performance_snapshot
ORDER BY total_revenue;

-- Top 10 most units sold
SELECT TOP 10 *
FROM sales_performance_snapshot
ORDER BY total_units_sold DESC;

-- Which store has the most revenue?
-- There is no direct connection between products and stores, however, 
-- the orders table contains the products and the store id, which can be used
-- to obtain total revenues
SELECT 
	st.store_name, 
	COUNT(DISTINCT o.order_id) AS total_orders,
	SUM(CAST(oi.quantity AS INT)) AS total_items_sold,
	ROUND(SUM(CAST(oi.quantity AS INT) * oi.list_price * (1 - oi.discount)), 2) AS total_revenue,
	ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
INTO stores_performance_snapshot
FROM stores st
JOIN orders o ON st.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY st.store_name;

SELECT * 
FROM stores_performance_snapshot
ORDER BY total_revenue DESC;

-- Baldwin Bikes sells a lot more items (4,779 so far, with 1,093 orders) compared to other stores, but Rowlett Bikes has a higher average order value.
-- Baldwin Bikes can be considered the "mass market" store, and they are more successful because they sell more items.
-- Rowlett Bikes has sold 1,566 items so far, with 174 total orders. The revenue is much less than Balwin Bikes,
-- however, the average order value is much higher (9,971 for Rowlett vs 4,771 for Baldwin), indicating that Rowlett is more for selling high-end bikes. 
-- Another possible conclusion can be that a customer may have ordered a batch of bikes, which caused such a spike in average.

SELECT MAX(list_price) FROM order_items;

SELECT TOP 1
	st.store_name,
	p.product_name,
	oi.list_price
FROM stores st
JOIN orders o ON st.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY oi.list_price DESC;

-- Baldwin has the most expensive bike.
-- The only plausible conclusion is that Rowlett has sold their most expensive bikes with their low volume sold to get such a 
-- high average order value.

SELECT
	st.store_name,
	ROUND(AVG(oi.list_price), 2) AS avg_item_price,
	MIN(oi.list_price) AS cheapest_item_sold,
	MAX(oi.list_price) AS most_expensive_item_sold
FROM stores st
JOIN orders o ON st.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY st.store_name
ORDER BY avg_item_price DESC;

-- Rowlett has slightly more average item price (1,228.56) compared to Baldwin (1,219.08)
-- Baldwin was able to sell their most expensive item, but on average, they sell cheaper items.