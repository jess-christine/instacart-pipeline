-- Orders Incremental MERGE


-- 1. Create the standardized and deduplicated merge source
CREATE OR REPLACE TEMP VIEW orders_merge_source AS

WITH typed_orders AS (
    SELECT
        TRY_CAST(order_id AS BIGINT) AS order_id,
        TRY_CAST(user_id AS BIGINT) AS user_id,
        LOWER(TRIM(eval_set)) AS eval_set,
        TRY_CAST(order_number AS INT) AS order_number,
        TRY_CAST(order_dow AS INT) AS order_dow,
        TRY_CAST(order_hour_of_day AS INT)
            AS order_hour_of_day,
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
                CASE
                    WHEN user_id IS NOT NULL THEN 0
                    ELSE 1
                END,
                order_number DESC,
                order_dow,
                order_hour_of_day
        ) AS rn
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
WHERE rn = 1
  AND order_id IS NOT NULL
  AND user_id IS NOT NULL
  AND eval_set IN ('prior', 'train', 'test')
  AND order_number IS NOT NULL
  AND order_number >= 1
  AND order_dow BETWEEN 0 AND 6
  AND order_hour_of_day BETWEEN 0 AND 23
  AND (
        days_since_prior_order BETWEEN 0 AND 30
        OR days_since_prior_order IS NULL
      );


-- 2. Merge Prior orders

MERGE INTO instacart.instacart_silver.orders_prior_silver AS target
USING (
    SELECT *
    FROM orders_merge_source
    WHERE eval_set = 'prior'
) AS source
ON target.order_id = source.order_id

WHEN MATCHED THEN UPDATE SET
    target.user_id = source.user_id,
    target.eval_set = source.eval_set,
    target.order_number = source.order_number,
    target.order_dow = source.order_dow,
    target.order_hour_of_day = source.order_hour_of_day,
    target.days_since_prior_order =
        source.days_since_prior_order

WHEN NOT MATCHED THEN INSERT (
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
)
VALUES (
    source.order_id,
    source.user_id,
    source.eval_set,
    source.order_number,
    source.order_dow,
    source.order_hour_of_day,
    source.days_since_prior_order
);


-- 3. Merge Train orders

MERGE INTO instacart.instacart_silver.orders_train_silver AS target
USING (
    SELECT *
    FROM orders_merge_source
    WHERE eval_set = 'train'
) AS source
ON target.order_id = source.order_id

WHEN MATCHED THEN UPDATE SET
    target.user_id = source.user_id,
    target.eval_set = source.eval_set,
    target.order_number = source.order_number,
    target.order_dow = source.order_dow,
    target.order_hour_of_day = source.order_hour_of_day,
    target.days_since_prior_order =
        source.days_since_prior_order

WHEN NOT MATCHED THEN INSERT (
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
)
VALUES (
    source.order_id,
    source.user_id,
    source.eval_set,
    source.order_number,
    source.order_dow,
    source.order_hour_of_day,
    source.days_since_prior_order
);


-- 4. Merge Test orders

MERGE INTO instacart.instacart_silver.orders_test_silver AS target
USING (
    SELECT *
    FROM orders_merge_source
    WHERE eval_set = 'test'
) AS source
ON target.order_id = source.order_id

WHEN MATCHED THEN UPDATE SET
    target.user_id = source.user_id,
    target.eval_set = source.eval_set,
    target.order_number = source.order_number,
    target.order_dow = source.order_dow,
    target.order_hour_of_day = source.order_hour_of_day,
    target.days_since_prior_order =
        source.days_since_prior_order

WHEN NOT MATCHED THEN INSERT (
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    days_since_prior_order
)
VALUES (
    source.order_id,
    source.user_id,
    source.eval_set,
    source.order_number,
    source.order_dow,
    source.order_hour_of_day,
    source.days_since_prior_order
);