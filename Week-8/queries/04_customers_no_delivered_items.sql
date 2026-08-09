-- 04: Customers who placed orders but never had any item delivered
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders_placed
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(CASE WHEN o.status = 'DELIVERED' THEN 1 ELSE 0 END) = 0
ORDER BY total_orders_placed DESC;
