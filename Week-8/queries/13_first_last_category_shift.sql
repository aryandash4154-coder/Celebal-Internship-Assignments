-- 13: First/Last Value Analysis for Category Shift Tracking
WITH ordered_purchases AS (
    SELECT 
        o.customer_id,
        p.category,
        o.order_date,
        FIRST_VALUE(p.category) OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_category,
        LAST_VALUE(p.category) OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS most_recent_category
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.customer_id != 'UNASSIGNED' AND o.status != 'CANCELLED'
)
SELECT DISTINCT
    customer_id,
    first_category,
    most_recent_category,
    CASE WHEN first_category != most_recent_category THEN 'Yes' ELSE 'No' END AS category_shift
FROM ordered_purchases
ORDER BY customer_id;
