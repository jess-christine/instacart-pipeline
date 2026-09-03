

USE CATALOG instacart;

-- 1. Create Target Gold Table with Primary Key and Timestamps
CREATE TABLE IF NOT EXISTS instacart.instacart_gold.dim_order (
  order_id BIGINT NOT NULL,
  user_id BIGINT,
  order_number INT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  CONSTRAINT dim_order_pk PRIMARY KEY(order_id)
)
USING DELTA
CLUSTER BY (order_id);

-- 2. Incremental MERGE Execution
MERGE INTO instacart.instacart_gold.dim_order AS tgt
USING (
  SELECT 
    order_id, 
    user_id, 
    order_number 
  FROM instacart.instacart_silver.orders_prior_silver
  
  UNION ALL
  
  SELECT 
    order_id, 
    user_id, 
    order_number 
  FROM instacart.instacart_silver.orders_train_silver

) AS src
ON tgt.order_id = src.order_id

WHEN MATCHED THEN UPDATE SET
  tgt.user_id = src.user_id,
  tgt.order_number = src.order_number,
  tgt.updated_at = current_timestamp()

WHEN NOT MATCHED THEN INSERT (
  order_id,
  user_id,
  order_number,
  created_at,
  updated_at
) VALUES (
  src.order_id,
  src.user_id,
  src.order_number,
  current_timestamp(),
  current_timestamp()
);