-- Create the Gold schema if it does not exist
CREATE SCHEMA IF NOT EXISTS instacart.instacart_gold;


-- Create the Gold dimension table
CREATE TABLE IF NOT EXISTS instacart.instacart_gold.dim_order_time (
    order_time_key INT PRIMARY KEY,
    order_dow INT,
    day_name STRING,
    order_hour_of_day INT,
    hour_label STRING,
    time_of_day STRING,
    is_weekend BOOLEAN,
    is_current BOOLEAN,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
USING DELTA;