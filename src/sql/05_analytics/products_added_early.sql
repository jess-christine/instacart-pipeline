-- Which products are commonly added early in an order?
-- Early means added within the first 3 positions.

WITH product_summary AS (
    SELECT
        p.product_id,
        p.product_name,

        COUNT(DISTINCT f.order_id)
            AS total_order_count,

        COUNT(
            DISTINCT CASE
                WHEN f.add_to_cart_order <= 3
                THEN f.order_id
            END
        ) AS early_order_count,

        ROUND(
            AVG(f.add_to_cart_order),
            2
        ) AS average_add_to_cart_order

    FROM instacart.instacart_gold.fact_order_items f
    INNER JOIN instacart.instacart_gold.dim_products p
        ON f.product_id = p.product_id

    WHERE f.add_to_cart_order IS NOT NULL

    GROUP BY
        p.product_id,
        p.product_name
)

SELECT
    product_name,
    early_order_count,
    total_order_count,

    ROUND(
        early_order_count * 100.0
        / total_order_count,
        2
    ) AS early_add_rate_percent,

    average_add_to_cart_order

FROM product_summary

-- Avoid ranking products with very few orders
WHERE total_order_count >= 100

ORDER BY
    early_order_count DESC,
    early_add_rate_percent DESC

LIMIT 10;