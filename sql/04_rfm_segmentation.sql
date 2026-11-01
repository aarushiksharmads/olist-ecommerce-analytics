-- 04_rfm_segmentation.sql

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(p.payment_value) AS order_value
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_payments p ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, o.order_id, o.order_purchase_timestamp
),
rfm_base AS (
    SELECT
        customer_unique_id,
        (SELECT MAX(order_purchase_timestamp)::date FROM customer_orders)
            - MAX(order_purchase_timestamp)::date          AS recency_days,
        COUNT(DISTINCT order_id)                           AS frequency,
        ROUND(SUM(order_value), 2)                         AS monetary
    FROM customer_orders
    GROUP BY customer_unique_id
),
rfm_scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        CASE WHEN frequency = 1 THEN 1
             WHEN frequency = 2 THEN 3
             ELSE 5 END                             AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 4 THEN 'Champions'
            WHEN f_score >= 3 AND r_score >= 3                   THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score = 1 AND m_score >= 4   THEN 'New Big Spenders'
            WHEN r_score >= 4 AND f_score = 1                    THEN 'New Customers'
            WHEN r_score <= 2 AND m_score >= 4                   THEN 'At Risk (High Value)'
            WHEN r_score <= 2                                    THEN 'Lost / Hibernating'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*)                                          AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_customers,
    ROUND(AVG(recency_days), 0)                       AS avg_recency_days,
    ROUND(AVG(frequency), 2)                          AS avg_orders,
    ROUND(AVG(monetary), 2)                           AS avg_spend,
    ROUND(SUM(monetary), 0)                           AS total_revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 2) AS pct_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;
