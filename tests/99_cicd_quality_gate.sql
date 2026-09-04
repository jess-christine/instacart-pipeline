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
           OR timekey IS NULL
           OR add_to_cart_order IS NULL
           OR reordered IS NULL
    ) = 0,
    'Gold fact table contains null required values'
);

-- Validate the declared grain: one row per order-product purchase.
SELECT assert_true(
    (SELECT COUNT(*) FROM instacart.instacart_gold.fact_order_items) =
    (
        SELECT COUNT(*)
        FROM (
            SELECT order_id, product_id
            FROM instacart.instacart_gold.fact_order_items
            GROUP BY order_id, product_id
        )
    ),
    'Gold fact table violates the (order_id, product_id) grain'
);

-- Validate source-to-model reconciliation for the modeled business event.
WITH joined_source AS (
    SELECT
        op.order_id,
        op.product_id,
        op.reordered,
        op._load_date AS source_load_date
    FROM instacart.instacart_silver.order_products_silver op
    INNER JOIN instacart.instacart_silver.orders_prior_silver o
        ON op.order_id = o.order_id
    INNER JOIN instacart.instacart_gold.dim_order_time t
        ON o.order_dow = t.order_dow
       AND o.order_hour_of_day = t.order_hour_of_day
    INNER JOIN instacart.instacart_gold.dim_products p
        ON op.product_id = p.product_id
),
deduplicated_source AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id, product_id
            ORDER BY source_load_date DESC NULLS LAST
        ) AS source_row_number
    FROM joined_source
),
expected_summary AS (
    SELECT
        COUNT(*) AS expected_items,
        COALESCE(
            SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END),
            0
        ) AS expected_reorders
    FROM deduplicated_source
    WHERE source_row_number = 1
),
actual_summary AS (
    SELECT
        COUNT(*) AS actual_items,
        COALESCE(
            SUM(CASE WHEN reordered THEN 1 ELSE 0 END),
            0
        ) AS actual_reorders
    FROM instacart.instacart_gold.fact_order_items
)
SELECT assert_true(
    (SELECT expected_items FROM expected_summary) =
        (SELECT actual_items FROM actual_summary)
    AND
    (SELECT expected_reorders FROM expected_summary) =
        (SELECT actual_reorders FROM actual_summary),
    'Gold fact table does not reconcile with the valid Silver order-product source'
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
        LEFT JOIN instacart.instacart_gold.dim_order o
            ON f.order_id = o.order_id
        WHERE o.order_id IS NULL
    ) = 0,
    'Gold fact table contains order foreign-key violations'
);

SELECT assert_true(
    (
        SELECT COUNT(*)
        FROM instacart.instacart_gold.fact_order_items f
        LEFT JOIN instacart.instacart_gold.dim_order_time t
            ON f.timekey = t.order_time_key
        WHERE t.order_time_key IS NULL
    ) = 0,
    'Gold fact table contains time foreign-key violations'
);
