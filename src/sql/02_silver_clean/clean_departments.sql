 --Create the clean table for department
CREATE TABLE IF NOT EXISTS instacart.instacart_clean.clean_departments(
    department_id INT PRIMARY KEY,
    department VARCHAR(100) UNIQUE,
    ingestion_timestamp TIMESTAMP,
    ingestion_date DATE
);

-- Insert cleaned data from raw table (this step makes sure that new entries from raw table will be cleaned before inserting into clean table)
INSERT INTO instacart.instacart_clean.clean_departments(department_id, department, ingestion_timestamp, ingestion_date)
SELECT DISTINCT
    department_id,
    LOWER(TRIM(department)) AS department,
    ingestion_timestamp,
    CAST(ingestion_timestamp AS DATE) AS ingestion_date
FROM instacart.instacart_raw.departments_raw
WHERE department_id IS NOT NULL;

--Query with CTE for future transformations
WITH standardized AS (
    SELECT 
        department_id,
        LOWER(TRIM(department)) AS department,
        ingestion_timestamp,
        ingestion_date
    FROM instacart.instacart_clean.clean_departments
)
SELECT *
FROM standardized;
