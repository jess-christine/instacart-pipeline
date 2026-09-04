-- Create the Fact Table
CREATE TABLE IF NOT EXISTS instacart.instacart_gold.fact_order_items (
    order_id BIGINT,
    product_id BIGINT,
    order_time_key INT,
    department_id INT,
    aisle_id INT,
    add_to_cart_order INT,
    reordered BOOLEAN,
    _load_date TIMESTAMP,
    _source_file STRING,
    PRIMARY KEY (order_id, product_id)   
);

-- Merge Into for incremental Load
MERGE INTO instacart.instacart_gold.fact_order_items AS target
USING (
    SELECT
        op.order_id,
        op.product_id,
        t.order_time_key,
        p.department_id,
        p.aisle_id,
        op.add_to_cart_order,
        op.reordered,
        CURRENT_TIMESTAMP() AS _load_date,
        'pipeline_batch' AS _source_file
    FROM instacart.instacart_silver.order_products_silver op
-- Used Inner Join to make sure only valid combinations are loaded
    JOIN instacart.instacart_silver.orders_prior_silver o
      ON op.order_id = o.order_id
    JOIN instacart.instacart_gold.dim_order_time t
      ON o.order_dow = t.order_dow
     AND o.order_hour_of_day = t.order_hour_of_day  
    JOIN instacart.instacart_gold.dim_products p
      ON op.product_id = p.product_id
) AS source
ON target.order_id = source.order_id
AND target.product_id = source.product_id

-- Only mutable columns are refreshed
WHEN MATCHED THEN UPDATE SET
    target.add_to_cart_order = source.add_to_cart_order,
    target.reordered = source.reordered,
    target._load_date = source._load_date,
    target._source_file = source._source_file

WHEN NOT MATCHED THEN INSERT (
    order_id, product_id, order_time_key, department_id, aisle_id,
    add_to_cart_order, reordered, _load_date, _source_file
) VALUES (
    source.order_id, source.product_id, source.order_time_key, source.department_id,
    source.aisle_id, source.add_to_cart_order, source.reordered,
    source._load_date, source._source_file
);
