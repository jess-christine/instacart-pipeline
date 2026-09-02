-- Data quality filters:
-- 1. Exclude records with missing aisle IDs
-- 2. Exclude records with missing aisle names
-- 3. Exclude records with blank aisle names
-- 4. Exclude non-positive aisle IDs to enforce valid business keys


-- Create Clean Aisles Table
CREATE TABLE IF NOT EXISTS instacart.instacart_clean.aisles_clean AS


WITH cleaned_source AS (


    SELECT
        CAST(aisle_id AS INT) AS aisle_id,
        TRIM(aisle) AS aisle_name,
        ingestion_timestamp,
        ingestion_date,


        -- Defensive deduplication to ensure one record per aisle_id
        ROW_NUMBER() OVER (
            PARTITION BY CAST(aisle_id AS INT)
            ORDER BY ingestion_timestamp DESC
        ) AS rn


    FROM instacart.instacart_raw.aisles_raw


    WHERE
        -- Remove NULL aisle IDs
        aisle_id IS NOT NULL


        -- Remove NULL aisle names
        AND aisle IS NOT NULL


        -- Remove blank aisle names
        AND TRIM(aisle) <> ''


        -- Remove invalid IDs
        AND CAST(aisle_id AS INT) > 0
)


SELECT
    aisle_id,
    aisle_name,
    ingestion_timestamp,
    ingestion_date


FROM cleaned_source


-- Keep only the first record for each aisle_id
WHERE rn = 1;


-- Validation Summary
SELECT
    (SELECT COUNT(*) FROM instacart.instacart_raw.aisles_raw) AS raw_row_count,
    (SELECT COUNT(*) FROM instacart.instacart_clean.aisles_clean) AS clean_row_count,


    (SELECT COUNT(*)
     FROM (
         SELECT aisle_id
         FROM instacart.instacart_clean.aisles_clean
         GROUP BY aisle_id
         HAVING COUNT(*) > 1
     )) AS duplicate_aisle_ids,


    (SELECT COUNT(*)
     FROM instacart.instacart_clean.aisles_clean
     WHERE aisle_id IS NULL) AS null_aisle_ids,


    (SELECT COUNT(*)
     FROM instacart.instacart_clean.aisles_clean
     WHERE aisle_name IS NULL) AS null_aisle_names,


    (SELECT COUNT(*)
     FROM instacart.instacart_clean.aisles_clean
     WHERE TRIM(aisle_name) = '') AS blank_aisle_names,


    (SELECT COUNT(*)
     FROM instacart.instacart_clean.aisles_clean
     WHERE aisle_id <= 0) AS invalid_aisle_ids,


    (SELECT COUNT(DISTINCT aisle_id)
     FROM instacart.instacart_raw.aisles_raw) AS raw_distinct_aisles,


    (SELECT COUNT(DISTINCT aisle_id)
     FROM instacart.instacart_clean.aisles_clean) AS clean_distinct_aisles;​‌

