-- Create the clean table for products
CREATE TABLE IF NOT EXISTS instacart.instacart_clean.products_clean (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    aisle_id INT NOT NULL,
    department_id INT NOT NULL,
    ingestion_timestamp TIMESTAMP,
    ingestion_date DATE
);

-- Standardize, validate, deduplicate, and merge product records
MERGE INTO instacart.instacart_clean.products_clean AS target

USING (
    SELECT
        product_id,
        product_name,
        aisle_id,
        department_id,
        ingestion_timestamp,
        ingestion_date
    FROM (
        SELECT
            TRY_CAST(product_id AS INT) AS product_id,

            TRIM(
                REGEXP_REPLACE(product_name, '\\s+', ' ')
            ) AS product_name,

            TRY_CAST(aisle_id AS INT) AS aisle_id,
            TRY_CAST(department_id AS INT) AS department_id,

            CAST(ingestion_timestamp AS TIMESTAMP)
                AS ingestion_timestamp,

            CAST(ingestion_timestamp AS DATE)
                AS ingestion_date,

            ROW_NUMBER() OVER (
                PARTITION BY TRY_CAST(product_id AS INT)
                ORDER BY CAST(ingestion_timestamp AS TIMESTAMP) DESC
            ) AS row_num

        FROM instacart.instacart_raw.products_raw

        WHERE product_id IS NOT NULL
          AND product_name IS NOT NULL
          AND TRIM(product_name) <> ''

          -- Reject malformed numeric values
          AND TRY_CAST(product_id AS INT) IS NOT NULL
          AND TRY_CAST(aisle_id AS INT) IS NOT NULL
          AND TRY_CAST(department_id AS INT) IS NOT NULL
    )
    WHERE row_num = 1
) AS source

ON target.product_id = source.product_id

WHEN MATCHED THEN
    UPDATE SET
        target.product_name = source.product_name,
        target.aisle_id = source.aisle_id,
        target.department_id = source.department_id,
        target.ingestion_timestamp = source.ingestion_timestamp,
        target.ingestion_date = source.ingestion_date

WHEN NOT MATCHED THEN
    INSERT (
        product_id,
        product_name,
        aisle_id,
        department_id,
        ingestion_timestamp,
        ingestion_date
    )
    VALUES (
        source.product_id,
        source.product_name,
        source.aisle_id,
        source.department_id,
        source.ingestion_timestamp,
        source.ingestion_date
    );