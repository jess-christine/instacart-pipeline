-- Create the clean table for department
CREATE TABLE IF NOT EXISTS instacart.instacart_clean.departments_clean (
    department_id INT PRIMARY KEY,
    department VARCHAR(100) UNIQUE,
    ingestion_timestamp TIMESTAMP,
    ingestion_date DATE
);

-- Merge cleaned data from raw table
MERGE INTO instacart.instacart_clean.departments_clean AS target
USING (
    SELECT DISTINCT
        department_id,
        LOWER(TRIM(department)) AS department,
        ingestion_timestamp,
        CAST(ingestion_timestamp AS DATE) AS ingestion_date
    FROM instacart.instacart_raw.departments_raw
    WHERE department_id IS NOT NULL
) AS source
ON target.department_id = source.department_id
WHEN MATCHED THEN
    UPDATE SET
        target.department = source.department,
        target.ingestion_timestamp = source.ingestion_timestamp,
        target.ingestion_date = source.ingestion_date
WHEN NOT MATCHED THEN
    INSERT (department_id, department, ingestion_timestamp, ingestion_date)
    VALUES (source.department_id, source.department, source.ingestion_timestamp, source.ingestion_date);
