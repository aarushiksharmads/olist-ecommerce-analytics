-- 03_cohort_retention.sql
-- Monthly cohorts by customer's first delivered order; retention by months since first purchase

WITH delivered AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohorts AS (
    SELECT
        customer_unique_id,
        order_month,
        MIN(order_month) OVER (PARTITION BY customer_unique_id) AS cohort_month
    FROM delivered
),
activity AS (
    SELECT
        cohort_month,
        ((EXTRACT(YEAR FROM order_month) - EXTRACT(YEAR FROM cohort_month)) * 12
         + EXTRACT(MONTH FROM order_month) - EXTRACT(MONTH FROM cohort_month))::int AS month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohorts
    GROUP BY 1, 2
)
SELECT
    cohort_month,
    month_number,
    active_customers,
    FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number) AS cohort_size,
    ROUND(100.0 * active_customers /
          FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number), 2) AS retention_pct
FROM activity
WHERE cohort_month BETWEEN '2017-01-01' AND '2018-08-01'
ORDER BY cohort_month, month_number;

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE orders_cnt >= 2) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders_cnt >= 2) / COUNT(*), 2) AS repeat_pct
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS orders_cnt
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
) t;
