-- 03: Month-wise order count for the last 12 months
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month DESC
LIMIT 12;
