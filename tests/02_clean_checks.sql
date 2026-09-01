-- tests/02_clean_checks.sql
-- Purpose: Data quality checks for the silver layer after transformation.

-- Instructions - what to put here:
-- 1) Primary key uniqueness checks for silver tables (orders, products, order_products).
-- 2) Data type validation: ensure numeric fields cast successfully and fall within expected ranges.
-- 3) Referential integrity: foreign keys in silver (e.g., order_products.order_id -> silver.orders.order_id).
-- 4) Null rate thresholds: set acceptable thresholds for non-critical columns and fail if exceeded for critical ones.
--
-- Example checks:
-- -- PK uniqueness
-- SELECT order_id, COUNT(*) FROM silver.orders GROUP BY order_id HAVING COUNT(*) > 1;
--
-- -- FK integrity
-- SELECT op.order_id FROM silver.order_products op LEFT JOIN silver.orders o ON op.order_id = o.order_id WHERE o.order_id IS NULL LIMIT 100;
--
-- Add the checks into your orchestration/CI and surface failures as tickets or alerts.





------- ** ORDERS CLEAN TABLE CHECKS** -----------



-- 1. Compare raw and Clean row counts

SELECT
    'prior' AS eval_set,
    (
        SELECT COUNT(*)
        FROM instacart.instacart_raw.orders_raw
        WHERE LOWER(TRIM(eval_set)) = 'prior'
    ) AS raw_count,
    (
        SELECT COUNT(*)
        FROM instacart.instacart_clean.orders_prior_clean
    ) AS clean_count

UNION ALL

SELECT
    'train' AS eval_set,
    (
        SELECT COUNT(*)
        FROM instacart.instacart_raw.orders_raw
        WHERE LOWER(TRIM(eval_set)) = 'train'
    ) AS raw_count,
    (
        SELECT COUNT(*)
        FROM instacart.instacart_clean.orders_train_clean
    ) AS clean_count

UNION ALL

SELECT
    'test' AS eval_set,
    (
        SELECT COUNT(*)
        FROM instacart.instacart_raw.orders_raw
        WHERE LOWER(TRIM(eval_set)) = 'test'
    ) AS raw_count,
    (
        SELECT COUNT(*)
        FROM instacart.instacart_clean.orders_test_clean
    ) AS clean_count;


-- 2. Check duplicate order_id values

SELECT
    'orders_prior_clean' AS table_name,
    order_id,
    COUNT(*) AS duplicate_count
FROM instacart.instacart_clean.orders_prior_clean
GROUP BY order_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'orders_train_clean' AS table_name,
    order_id,
    COUNT(*) AS duplicate_count
FROM instacart.instacart_clean.orders_train_clean
GROUP BY order_id
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'orders_test_clean' AS table_name,
    order_id,
    COUNT(*) AS duplicate_count
FROM instacart.instacart_clean.orders_test_clean
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 3. Check that each table contains the correct eval_set

SELECT
    'orders_prior_clean' AS table_name,
    COUNT(*) AS invalid_eval_set_rows
FROM instacart.instacart_clean.orders_prior_clean
WHERE eval_set IS NULL
   OR eval_set <> 'prior'

UNION ALL

SELECT
    'orders_train_clean' AS table_name,
    COUNT(*) AS invalid_eval_set_rows
FROM instacart.instacart_clean.orders_train_clean
WHERE eval_set IS NULL
   OR eval_set <> 'train'

UNION ALL

SELECT
    'orders_test_clean' AS table_name,
    COUNT(*) AS invalid_eval_set_rows
FROM instacart.instacart_clean.orders_test_clean
WHERE eval_set IS NULL
   OR eval_set <> 'test';


-- 4. Check NULLs and valid value ranges

SELECT
    'orders_prior_clean' AS table_name,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)
        AS missing_order_id,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END)
        AS missing_user_id,
    SUM(CASE WHEN order_number IS NULL OR order_number < 1
        THEN 1 ELSE 0 END) AS invalid_order_number,
    SUM(CASE WHEN order_dow NOT BETWEEN 0 AND 6
        THEN 1 ELSE 0 END) AS invalid_order_dow,
    SUM(CASE WHEN order_hour_of_day NOT BETWEEN 0 AND 23
        THEN 1 ELSE 0 END) AS invalid_order_hour,
    SUM(
        CASE
            WHEN days_since_prior_order IS NOT NULL
             AND (
                    days_since_prior_order < 0
                    OR days_since_prior_order > 30
                 )
            THEN 1 ELSE 0
        END
    ) AS invalid_days_since_prior_order
FROM instacart.instacart_clean.orders_prior_clean

UNION ALL

SELECT
    'orders_train_clean',
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_number IS NULL OR order_number < 1
        THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_dow NOT BETWEEN 0 AND 6
        THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_hour_of_day NOT BETWEEN 0 AND 23
        THEN 1 ELSE 0 END),
    SUM(
        CASE
            WHEN days_since_prior_order IS NOT NULL
             AND (
                    days_since_prior_order < 0
                    OR days_since_prior_order > 30
                 )
            THEN 1 ELSE 0
        END
    )
FROM instacart.instacart_clean.orders_train_clean

UNION ALL

SELECT
    'orders_test_clean',
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_number IS NULL OR order_number < 1
        THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_dow NOT BETWEEN 0 AND 6
        THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_hour_of_day NOT BETWEEN 0 AND 23
        THEN 1 ELSE 0 END),
    SUM(
        CASE
            WHEN days_since_prior_order IS NOT NULL
             AND (
                    days_since_prior_order < 0
                    OR days_since_prior_order > 30
                 )
            THEN 1 ELSE 0
        END
    )
FROM instacart.instacart_clean.orders_test_clean;


-- 5. Check order_products foreign keys

WITH all_clean_orders AS (
    SELECT order_id
    FROM instacart.instacart_clean.orders_prior_clean

    UNION ALL

    SELECT order_id
    FROM instacart.instacart_clean.orders_train_clean

    UNION ALL

    SELECT order_id
    FROM instacart.instacart_clean.orders_test_clean
),
distinct_clean_orders AS (
    SELECT DISTINCT order_id
    FROM all_clean_orders
)

SELECT
    COUNT(*) AS total_order_product_rows,
    SUM(
        CASE
            WHEN o.order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_order_parent_rows
FROM instacart.instacart_clean.order_products op
LEFT JOIN distinct_clean_orders o
    ON op.order_id = o.order_id;