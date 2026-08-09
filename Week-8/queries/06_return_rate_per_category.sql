-- 06: Calculate the return rate (returned items / total items) per category
SELECT 
    p.category,
    SUM(CASE WHEN oi.quantity > 0 THEN oi.quantity ELSE 0 END) AS total_purchased_items,
    ABS(SUM(CASE WHEN oi.quantity < 0 THEN oi.quantity ELSE 0 END)) AS total_returned_items,
    ROUND(
        ABS(SUM(CASE WHEN oi.quantity < 0 THEN oi.quantity ELSE 0 END)) * 100.0 / 
        NULLIF(SUM(CASE WHEN oi.quantity > 0 THEN oi.quantity ELSE 0 END), 0),
        2
    ) AS return_rate_percent
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_percent DESC;
