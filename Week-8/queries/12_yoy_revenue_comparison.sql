-- 12: Year-over-Year (YoY) Revenue Comparison
WITH monthly_revenue AS (
    SELECT 
        YEAR(o.order_date) AS rev_year,
        MONTH(o.order_date) AS rev_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status != 'CANCELLED'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
)
SELECT 
    curr.rev_year AS year,
    curr.rev_month AS month,
    curr.revenue,
    prev.revenue AS prev_year_revenue,
    ROUND(
        CASE 
            WHEN prev.revenue IS NULL OR prev.revenue = 0 THEN NULL
            ELSE ((curr.revenue - prev.revenue) * 100.0 / prev.revenue)
        END, 2
    ) AS yoy_growth_percent
FROM monthly_revenue curr
LEFT JOIN monthly_revenue prev 
    ON curr.rev_year = prev.rev_year + 1 
   AND curr.rev_month = prev.rev_month
ORDER BY curr.rev_year, curr.rev_month;
