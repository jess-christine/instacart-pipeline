-- Create the Gold schema if it does not exist
CREATE SCHEMA IF NOT EXISTS instacart.instacart_gold;

-- Create the Gold dimension table
CREATE TABLE IF NOT EXISTS instacart.instacart_gold.dim_order_time (
    order_time_key INT PRIMARY KEY, -- Integer Surrogate Key format: (DOW * 100 + HoD) e.g., 610
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
) USING DELTA;

INSERT OVERWRITE TABLE instacart.instacart_gold.dim_order_time
SELECT DISTINCT
    (order_dow * 100) + order_hour_of_day AS order_time_key, -- Col 1: INT (e.g., 610)
    CAST(order_dow AS INT) AS order_dow,                      -- Col 2: INT
    CASE order_dow                                            -- Col 3: STRING
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    CAST(order_hour_of_day AS INT) AS order_hour_of_day,       -- Col 4: INT
    CONCAT(LPAD(CAST(order_hour_of_day AS STRING), 2, '0'), ':00') AS hour_label, -- Col 5: STRING
    CASE                                                         -- Col 6: STRING
        WHEN order_hour_of_day BETWEEN 5 AND 11 THEN 'Morning'
        WHEN order_hour_of_day BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN order_hour_of_day BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,
    IF(order_dow IN (0, 6), TRUE, FALSE) AS is_weekend,          -- Col 7: BOOLEAN
    TRUE AS is_current,                                          -- Col 8: BOOLEAN
    CURRENT_TIMESTAMP() AS valid_from,                           -- Col 9: TIMESTAMP
    CAST(NULL AS TIMESTAMP) AS valid_to,                         -- Col 10: TIMESTAMP
    CURRENT_TIMESTAMP() AS created_at,                           -- Col 11: TIMESTAMP
    CURRENT_TIMESTAMP() AS updated_at                            -- Col 12: TIMESTAMP
FROM (
    SELECT TRY_CAST(order_dow AS INT) AS order_dow, TRY_CAST(order_hour_of_day AS INT) AS order_hour_of_day 
    FROM instacart.instacart_silver.orders_prior_silver
    WHERE TRY_CAST(order_dow AS INT) IS NOT NULL AND TRY_CAST(order_hour_of_day AS INT) IS NOT NULL
    
    UNION
    
    SELECT TRY_CAST(order_dow AS INT) AS order_dow, TRY_CAST(order_hour_of_day AS INT) AS order_hour_of_day 
    FROM instacart.instacart_silver.orders_train_silver
    WHERE TRY_CAST(order_dow AS INT) IS NOT NULL AND TRY_CAST(order_hour_of_day AS INT) IS NOT NULL
    
    UNION
    
    SELECT TRY_CAST(order_dow AS INT) AS order_dow, TRY_CAST(order_hour_of_day AS INT) AS order_hour_of_day 
    FROM instacart.instacart_silver.orders_test_silver
    WHERE TRY_CAST(order_dow AS INT) IS NOT NULL AND TRY_CAST(order_hour_of_day AS INT) IS NOT NULL
);