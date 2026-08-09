-- 15: Complex CTE Cohort Analysis
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_FORMAT(registration_date, '%Y-%m') AS cohort_month,
        registration_date
    FROM customers
),
customer_activity AS (
    SELECT DISTINCT
        c.customer_id,
        c.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_date, '%Y%m'), 
            DATE_FORMAT(c.registration_date, '%Y%m')
        ) AS month_number
    FROM customer_cohorts c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status != 'CANCELLED'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS total_registered
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT 
    ca.cohort_month,
    cs.total_registered,
    COUNT(DISTINCT CASE WHEN ca.month_number = 0 THEN ca.customer_id END) AS m0_orders,
    COUNT(DISTINCT CASE WHEN ca.month_number = 1 THEN ca.customer_id END) AS m1_orders,
    COUNT(DISTINCT CASE WHEN ca.month_number = 2 THEN ca.customer_id END) AS m2_orders,
    COUNT(DISTINCT CASE WHEN ca.month_number = 3 THEN ca.customer_id END) AS m3_orders,
    ROUND(COUNT(DISTINCT CASE WHEN ca.month_number = 1 THEN ca.customer_id END) * 100.0 / cs.total_registered, 1) AS m1_retention_pct,
    ROUND(COUNT(DISTINCT CASE WHEN ca.month_number = 2 THEN ca.customer_id END) * 100.0 / cs.total_registered, 1) AS m2_retention_pct,
    ROUND(COUNT(DISTINCT CASE WHEN ca.month_number = 3 THEN ca.customer_id END) * 100.0 / cs.total_registered, 1) AS m3_retention_pct
FROM customer_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.month_number BETWEEN 0 AND 3
GROUP BY ca.cohort_month, cs.total_registered
ORDER BY ca.cohort_month;
