-- 05_delivery_vs_reviews.sql

WITH latest_review AS (
    SELECT
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
),
delivery AS (
    SELECT
        o.order_id,
        (o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date) AS days_vs_estimate,
        (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date)      AS delivery_days,
        r.review_score
    FROM orders o
    JOIN latest_review r ON r.order_id = o.order_id AND r.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),
bucketed AS (
    SELECT
        *,
        CASE
            WHEN days_vs_estimate < -7 THEN '1. Early (>7 days before estimate)'
            WHEN days_vs_estimate <= 0 THEN '2. On time / slightly early'
            WHEN days_vs_estimate <= 3 THEN '3. Late 1-3 days'
            WHEN days_vs_estimate <= 7 THEN '4. Late 4-7 days'
            ELSE '5. Late 8+ days'
        END AS delivery_bucket
    FROM delivery
)
SELECT
    delivery_bucket,
    COUNT(*)                                                        AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)              AS pct_orders,
    ROUND(AVG(review_score), 2)                                     AS avg_review_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 2) AS pct_bad_reviews,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score = 5) / COUNT(*), 2)  AS pct_five_star
FROM bucketed
GROUP BY delivery_bucket
ORDER BY delivery_bucket;

SELECT
    c.customer_state,
    COUNT(*) AS orders,
    ROUND(AVG(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date), 1) AS avg_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) / COUNT(*), 2) AS pct_late
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;
