-- 09: LAG/LEAD Analysis for Customer Purchase Interval & Risk Flagging
WITH customer_order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
        DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_gap
    FROM orders
    WHERE customer_id != 'UNASSIGNED' AND customer_id IS NOT NULL
),
customer_avg_gaps AS (
    SELECT 
        customer_id,
        AVG(days_gap) AS avg_days_gap
    FROM customer_order_gaps
    WHERE days_gap IS NOT NULL
    GROUP BY customer_id
)
SELECT 
    g.customer_id,
    g.order_date,
    g.previous_order_date,
    g.days_gap,
    ROUND(a.avg_days_gap, 1) AS avg_days_gap,
    CASE WHEN a.avg_days_gap > 30 THEN 'At Risk' ELSE 'Active' END AS risk_status
FROM customer_order_gaps g
LEFT JOIN customer_avg_gaps a ON g.customer_id = a.customer_id
ORDER BY g.customer_id, g.order_date;
