-- Row count
SELECT COUNT(*) AS row_count
FROM instacart.instacart_raw.aisles_raw;

-- Check for duplicate aisle_id
SELECT
    aisle_id,
    COUNT(*) AS record_count
FROM instacart.instacart_raw.aisles_raw
GROUP BY aisle_id
HAVING COUNT(*) > 1;

-- Check for NULLs
SELECT
    SUM(CASE WHEN aisle_id IS NULL THEN 1 ELSE 0 END) AS null_aisle_id,
    SUM(CASE WHEN aisle IS NULL THEN 1 ELSE 0 END) AS null_aisle
FROM instacart.instacart_raw.aisles_raw;

-- Check for blank names
SELECT *
FROM instacart.instacart_raw.aisles_raw
WHERE TRIM(aisle) = '';

-- Check for rescued records
SELECT *
FROM instacart.instacart_raw.aisles_raw
WHERE _rescued_data IS NOT NULL;

-- Check for invalid IDs
SELECT *
FROM instacart.instacart_raw.aisles_raw
WHERE aisle_id <= 0;

CREATE OR REPLACE TABLE instacart.instacart_clean.aisles_clean AS
SELECT
    CAST(aisle_id AS INT) AS aisle_id,
    TRIM(aisle) AS aisle_name,
    ingestion_timestamp,
    ingestion_date
FROM instacart.instacart_raw.aisles_raw;