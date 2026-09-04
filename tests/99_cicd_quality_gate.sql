-- Release quality gate.
-- assert_true raises USER_RAISED_EXCEPTION when a check fails, which makes the
-- Databricks job and the GitHub deployment fail together.

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_bronze.aisles_bronze) > 0,
    'Bronze aisles table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_bronze.departments_bronze) > 0,
    'Bronze departments table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_bronze.orders_bronze) > 0,
    'Bronze orders table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_bronze.products_bronze) > 0,
    'Bronze products table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_bronze.order_products_prior_bronze) > 0,
    'Bronze prior order-products table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_bronze.order_products_train_bronze) > 0,
    'Bronze train order-products table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_silver.orders_prior_silver) > 0,
    'Silver prior orders table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_silver.products_silver) > 0,
    'Silver products table is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_gold.dim_products) > 0,
    'Gold product dimension is empty'
);

SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_gold.fact_order_items) > 0,
    'Gold fact table is empty'
);

SELECT assert_true(
    (
        SELECT COUNT(*)
        FROM instacart.instacart_gold.fact_order_items
        WHERE order_id IS NULL
           OR product_id IS NULL
           OR order_time_key IS NULL
           OR add_to_cart_order IS NULL
           OR reordered IS NULL
    ) = 0,
    'Gold fact table contains null required values'
);

SELECT assert_true(
    (
        SELECT COUNT(*)
        FROM (
            SELECT order_id, product_id
            FROM instacart.instacart_gold.fact_order_items
            GROUP BY order_id, product_id
            HAVING COUNT(*) > 1
        )
    ) = 0,
    'Gold fact table contains duplicate order-product keys'
);

SELECT assert_true(
    (
        SELECT COUNT(*)
        FROM instacart.instacart_gold.fact_order_items f
        LEFT JOIN instacart.instacart_gold.dim_products p
            ON f.product_id = p.product_id
        WHERE p.product_id IS NULL
    ) = 0,
    'Gold fact table contains product foreign-key violations'
);

SELECT assert_true(
    (
        SELECT COUNT(*)
        FROM instacart.instacart_gold.fact_order_items f
        LEFT JOIN instacart.instacart_gold.dim_order_time t
            ON f.order_time_key = t.order_time_key
        WHERE t.order_time_key IS NULL
    ) = 0,
    'Gold fact table contains time foreign-key violations'
);
