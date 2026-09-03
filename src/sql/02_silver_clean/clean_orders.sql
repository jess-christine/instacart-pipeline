CREATE OR REPLACE TEMP VIEW orders_staging AS
WITH typed_orders AS (
    SELECT
        TRY_CAST(order_id AS BIGINT) AS order_id,
        TRY_CAST(user_id AS BIGINT) AS user_id,
        LOWER(TRIM(eval_set)) AS eval_set,
        TRY_CAST(order_number AS INT) AS order_number,
        TRY_CAST(order_dow AS INT) AS order_dow,
        TRY_CAST(order_hour_of_day AS INT) AS order_hour_of_day,
        TRY_CAST(days_since_prior_order AS DOUBLE)
            AS days_since_prior_order
    FROM instacart.instacart_bronze.orders_bronze
),
ranked_orders AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                CASE WHEN user_id IS NOT NULL THEN 0 ELSE 1 END,
                order_number DESC,
                order_dow,
                order_hour_of_day
        ) AS row_number
    FROM typed_orders
)
SELECT
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
FROM ranked_orders
WHERE row_number = 1;


CREATE TABLE IF NOT EXISTS instacart.instacart_silver.orders_prior_silver AS
SELECT
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
FROM orders_staging
WHERE eval_set = 'prior'
  AND order_id IS NOT NULL
  AND user_id IS NOT NULL
  AND order_number IS NOT NULL
  AND order_dow BETWEEN 0 AND 6
  AND order_hour_of_day BETWEEN 0 AND 23
  AND (
        days_since_prior_order BETWEEN 0 AND 30
        OR days_since_prior_order IS NULL
      );


CREATE TABLE IF NOT EXISTS instacart.instacart_silver.orders_train_silver AS
SELECT
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
FROM orders_staging
WHERE eval_set = 'train'
  AND order_id IS NOT NULL
  AND user_id IS NOT NULL
  AND order_number IS NOT NULL
  AND order_dow BETWEEN 0 AND 6
  AND order_hour_of_day BETWEEN 0 AND 23
  AND (
        days_since_prior_order BETWEEN 0 AND 30
        OR days_since_prior_order IS NULL
      );
CREATE TABLE IF NOT EXISTS instacart.instacart_silver.orders_test_silver AS
SELECT
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
FROM orders_staging
WHERE eval_set = 'test'
  AND order_id IS NOT NULL
  AND user_id IS NOT NULL
  AND order_number IS NOT NULL
  AND order_dow BETWEEN 0 AND 6
  AND order_hour_of_day BETWEEN 0 AND 23
  AND (
        days_since_prior_order BETWEEN 0 AND 30
        OR days_since_prior_order IS NULL
      );