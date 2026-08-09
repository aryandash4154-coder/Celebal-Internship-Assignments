-- 14: Cumulative Distribution (Pareto 80/20 Analysis)
WITH customer_rev AS (
    SELECT 
        o.customer_id,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id != 'UNASSIGNED' AND o.status != 'CANCELLED'
    GROUP BY o.customer_id
),
grand_total AS (
    SELECT SUM(revenue) AS total_company_revenue FROM customer_rev
),
running_rev AS (
    SELECT 
        cr.customer_id,
        cr.revenue,
        SUM(cr.revenue) OVER (ORDER BY cr.revenue DESC) AS cumulative_revenue,
        gt.total_company_revenue
    FROM customer_rev cr
    CROSS JOIN grand_total gt
)
SELECT 
    customer_id,
    revenue,
    cumulative_revenue,
    ROUND((cumulative_revenue * 100.0 / total_company_revenue), 2) AS cumulative_percent
FROM running_rev
ORDER BY revenue DESC;
