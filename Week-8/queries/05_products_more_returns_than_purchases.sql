-- 05: Products that were ordered but had more returns than purchases
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(CASE WHEN oi.quantity > 0 THEN oi.quantity ELSE 0 END) AS total_purchased_qty,
    ABS(SUM(CASE WHEN oi.quantity < 0 THEN oi.quantity ELSE 0 END)) AS total_returned_qty
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING total_returned_qty > total_purchased_qty
ORDER BY total_returned_qty DESC;
