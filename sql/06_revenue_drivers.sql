-- 06_revenue_drivers.sql

-- 6A. Monthly revenue, orders, AOV, MoM growth
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        COUNT(DISTINCT o.order_id)  AS orders,
        SUM(oi.price)               AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    orders,
    ROUND(revenue, 0)                      AS revenue,
    ROUND(revenue / orders, 2)             AS avg_order_value,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
WHERE month BETWEEN '2017-01-01' AND '2018-08-01'
ORDER BY month;

-- 6B. Revenue by category with cumulative share
WITH cat AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
        COUNT(DISTINCT oi.order_id) AS orders,
        SUM(oi.price)               AS revenue
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    RANK() OVER (ORDER BY revenue DESC)                              AS rnk,
    category,
    orders,
    ROUND(revenue, 0)                                                AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                 AS pct_revenue,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2)                                 AS cumulative_pct
FROM cat
ORDER BY revenue DESC
LIMIT 15;

-- 6C. Revenue by customer state
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id)                                       AS orders,
    ROUND(SUM(oi.price), 0)                                          AS revenue,
    ROUND(100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2)     AS pct_revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)             AS avg_order_value
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- 6D. Revenue by payment type
SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id)                                       AS orders,
    ROUND(SUM(p.payment_value), 0)                                   AS payment_value,
    ROUND(100.0 * SUM(p.payment_value) / SUM(SUM(p.payment_value)) OVER (), 2) AS pct_value,
    ROUND(AVG(p.payment_installments), 1)                            AS avg_installments
FROM order_payments p
JOIN orders o ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY payment_value DESC;

-- 6E. Top 10 sellers by revenue
SELECT
    RANK() OVER (ORDER BY SUM(oi.price) DESC)                        AS rnk,
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                                      AS orders,
    ROUND(SUM(oi.price), 0)                                          AS revenue,
    ROUND(100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2)     AS pct_revenue
FROM order_items oi
JOIN orders o  ON o.order_id = oi.order_id
JOIN sellers s ON s.seller_id = oi.seller_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, s.seller_state
ORDER BY revenue DESC
LIMIT 10;
