/*
Purpose: Create the DimProducts dimension table for reporting and analysis.

SCD Type: Type 1 (Overwrite)

    Reason:
    - Product attributes rarely change.
    - Historical tracking is not required for this project.
    - The dataset is static and loaded once for this portfolio project.

MERGE / UPSERT Strategy:
- This project uses a one-time CTAS load with CREATE TABLE IF NOT EXISTS.
- This minimizes compute consumption in the free trial environment.
- In a production environment, MERGE/UPSERT logic would be used to process new and changed records.

Backfill Approach:
- Perform a full load from the cleaned products, aisles, and departments tables.

Future Change Handling:
- Not implemented for this portfolio project.
- Future refreshes would require dropping the table and rerunning the load or replacing the CTAS with MERGE logic.

Attribute Normalization:
- Product names are standardized using TRIM() and INITCAP().
- This removes leading/trailing spaces and applies consistent capitalization.

Example:
' organic bananas ' -> 'Organic Bananas'
'ORGANIC BANANAS' -> 'Organic Bananas'

Missing Foreign Key Handling:
- LEFT JOINs are used to preserve all product records.
- Clean dimension tables enforce data quality through validation and deduplication.
- Any unmatched aisle_id or department_id values can be identified through validation queries.
*/

-- Create DimProducts
CREATE TABLE IF NOT EXISTS instacart.instacart_gold.dim_products AS

SELECT
    p.product_id,
    INITCAP(TRIM(p.product_name)) AS product_name,

    a.aisle_id,
    a.aisle_name AS aisle,

    d.department_id,
    d.department AS department

FROM instacart.instacart_clean.products_clean p

LEFT JOIN instacart.instacart_clean.aisles_clean a
    ON p.aisle_id = a.aisle_id

LEFT JOIN instacart.instacart_clean.departments_clean d
    ON p.department_id = d.department_id;


/*
Post-Load Validation

Detailed data quality assertions are maintained in
data_quality_checks.sql and should be executed before
promoting DimProducts to downstream reporting layers.
*/

Validation

Expected:
- source_count = dim_count
- duplicate_product_ids = 0
- unmatched_aisle_records = 0
- unmatched_department_records = 0
*/

SELECT
    (SELECT COUNT(*)
     FROM instacart.instacart_clean.products_clean) AS source_count,

    (SELECT COUNT(*)
     FROM instacart.instacart_gold.dim_products) AS dim_count,

    (SELECT COUNT(*)
     FROM (
         SELECT product_id
         FROM instacart.instacart_gold.dim_products
         GROUP BY product_id
         HAVING COUNT(*) > 1
     )) AS duplicate_product_ids,

    (SELECT COUNT(*)
     FROM instacart.instacart_gold.dim_products
     WHERE aisle_id IS NULL) AS unmatched_aisle_records,

    (SELECT COUNT(*)
     FROM instacart.instacart_gold.dim_products
     WHERE department_id IS NULL) AS unmatched_department_records;


/*
Since this dimension uses SCD Type 1,
historical versions are not retained.

Each product_id should have exactly one current record.
*/