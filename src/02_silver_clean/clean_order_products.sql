USE CATALOG instacart;

-- 1. Create Target Silver Table (Idempotent)
CREATE TABLE IF NOT EXISTS instacart.instacart_clean.order_products_clean (
  order_id BIGINT,
  product_id BIGINT,
  add_to_cart_order INT,
  reordered INT,
  dataset_source STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  _load_date TIMESTAMP,
  _batch_date DATE
)
USING DELTA
CLUSTER BY (order_id, product_id);

-- 2. Dynamic MERGE Execution (dedup + basic validation, no DQ flag columns)
MERGE INTO instacart.instacart_clean.order_products_clean AS tgt
USING (
  WITH raw_source AS (
    SELECT 
      CAST(order_id AS BIGINT) AS order_id,
      CAST(product_id AS BIGINT) AS product_id,
      CAST(add_to_cart_order AS INT) AS add_to_cart_order,
      CAST(reordered AS INT) AS reordered,
      :dataset_label AS dataset_source,
      ingestion_timestamp,
      ingestion_date
    FROM instacart_raw.IDENTIFIER(:source_table)
  ),

  attribute_checks AS (
    SELECT 
      *,
      (order_id IS NULL OR product_id IS NULL) AS is_null_key,
      (add_to_cart_order IS NULL OR add_to_cart_order <= 0) AS is_invalid_cart_order,
      (reordered NOT IN (0, 1) OR reordered IS NULL) AS is_invalid_reordered
    FROM raw_source
  ),

  duplicate_checks AS (
    SELECT 
      *,
      ROW_NUMBER() OVER (
        PARTITION BY order_id, product_id 
        ORDER BY ingestion_timestamp DESC
      ) AS rn
    FROM attribute_checks
  )

  SELECT
    order_id,
    product_id,
    add_to_cart_order,
    COALESCE(reordered, 0) AS reordered,
    dataset_source,
    current_timestamp() AS created_at,
    current_timestamp() AS updated_at,
    ingestion_timestamp AS _load_date,
    ingestion_date AS _batch_date
  FROM duplicate_checks
  WHERE
    is_null_key = FALSE
    AND is_invalid_cart_order = FALSE
    AND is_invalid_reordered = FALSE
    AND rn = 1
) AS src
ON tgt.order_id = src.order_id 
AND tgt.product_id = src.product_id

WHEN MATCHED THEN UPDATE SET
  add_to_cart_order = src.add_to_cart_order,
  reordered = src.reordered,
  dataset_source = src.dataset_source,
  updated_at = src.updated_at,
  _load_date = src._load_date,
  _batch_date = src._batch_date

WHEN NOT MATCHED THEN INSERT (
  order_id,
  product_id,
  add_to_cart_order,
  reordered,
  dataset_source,
  created_at,
  updated_at,
  _load_date,
  _batch_date
) VALUES (
  src.order_id,
  src.product_id,
  src.add_to_cart_order,
  src.reordered,
  src.dataset_source,
  src.created_at,
  src.updated_at,
  src._load_date,
  src._batch_date
);