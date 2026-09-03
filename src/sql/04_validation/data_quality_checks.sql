/*
Purpose: Contain isolated assertions and checks used as quality gates before promoting to gold.

Instructions - what to put here:
1) List the required data quality checks (PK uniqueness, FK referential integrity, null-rate thresholds, row-count sanity checks).
2) For each check, provide the SQL query to assert the condition and the failure criteria.
3) Describe how failures should be handled (alerting, blocking promotion, creating issues with example diagnostics).
4) Recommend integration with a test harness or DQ tool (dbt tests, Great Expectations, or custom scripts) and show example invocation steps.

Operational: Include sample thresholds and recommendations for acceptable error rates and SLA for fixes.

/*
Purpose: Data quality checks for DimProducts before promotion to gold.

Checks:
- PK uniqueness
- FK integrity
- Null / blank values
- Row count sanity

Failure Handling:
- Block promotion if any check fails.
- Run diagnostics queries to identify affected records.
- Create a defect ticket with failing results and sample records.
- Notify the pipeline owner through the team's alerting process.
- Target SLA: 1 business day.
*/


-- PK Uniqueness
-- Expected: 0
-- Failure: duplicate_product_ids > 0
SELECT COUNT(*) AS duplicate_product_ids
FROM (
    SELECT product_id
    FROM instacart.instacart_gold.dim_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
);


-- FK Integrity: Aisles
-- Expected: 0
-- Failure: orphan_aisle_keys > 0
SELECT COUNT(*) AS orphan_aisle_keys
FROM instacart.instacart_gold.dim_products p
LEFT JOIN instacart.instacart_clean.aisles_clean a
    ON p.aisle_id = a.aisle_id
WHERE a.aisle_id IS NULL;


-- FK Integrity: Departments
-- Expected: 0
-- Failure: orphan_department_keys > 0
SELECT COUNT(*) AS orphan_department_keys
FROM instacart.instacart_gold.dim_products p
LEFT JOIN instacart.instacart_clean.departments_clean d
    ON p.department_id = d.department_id
WHERE d.department_id IS NULL;


-- Null / Blank Checks
-- Expected: 0 for all columns
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_ids,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS null_product_names,
    SUM(CASE WHEN TRIM(product_name) = '' THEN 1 ELSE 0 END) AS blank_product_names
FROM instacart.instacart_gold.dim_products;


-- Row Count Sanity Check
-- Expected: source_count = dim_count
-- Failure: row count variance > 5%
SELECT
    (SELECT COUNT(*)
     FROM instacart.instacart_clean.products_clean) AS source_count,

    (SELECT COUNT(*)
     FROM instacart.instacart_gold.dim_products) AS dim_count;


-- Diagnostics (run if a check fails)
SELECT *
FROM instacart.instacart_gold.dim_products
WHERE product_id IS NULL
   OR product_name IS NULL
   OR TRIM(product_name) = '';


/*
Automation Recommendation

Preferred Tool:
- dbt

Command:
dbt test --select dim_products

Alternatives:
- Great Expectations
- Custom SQL validation scripts executed before gold promotion

Suggested Thresholds:
- Duplicate PKs: 0
- Orphan FKs: 0
- Null IDs: 0
- Null/Blank Names: 0
- Row Count Variance: <= 5%

Promotion Rule:
- Promote to gold only if all checks pass.
*/
Purpose: Data quality checks for DimProducts before promotion to gold.

Checks:
- PK uniqueness
- FK integrity
- Null / blank values
- Row count sanity

Failure Handling:
- Block promotion if any check fails.
- Run diagnostics queries to identify affected records.
- Create a defect ticket with failing results and sample records.
- Notify the pipeline owner through the team's alerting process.
- Target SLA: 1 business day.
*/


-- PK Uniqueness
-- Expected: 0
-- Failure: duplicate_product_ids > 0
SELECT COUNT(*) AS duplicate_product_ids
FROM (
    SELECT product_id
    FROM instacart.instacart_gold.dim_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
);


-- FK Integrity: Aisles
-- Expected: 0
-- Failure: orphan_aisle_keys > 0
SELECT COUNT(*) AS orphan_aisle_keys
FROM instacart.instacart_gold.dim_products p
LEFT JOIN instacart.instacart_clean.aisles_clean a
    ON p.aisle_id = a.aisle_id
WHERE a.aisle_id IS NULL;


-- FK Integrity: Departments
-- Expected: 0
-- Failure: orphan_department_keys > 0
SELECT COUNT(*) AS orphan_department_keys
FROM instacart.instacart_gold.dim_products p
LEFT JOIN instacart.instacart_clean.departments_clean d
    ON p.department_id = d.department_id
WHERE d.department_id IS NULL;


-- Null / Blank Checks
-- Expected: 0 for all columns
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_ids,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS null_product_names,
    SUM(CASE WHEN TRIM(product_name) = '' THEN 1 ELSE 0 END) AS blank_product_names
FROM instacart.instacart_gold.dim_products;


-- Row Count Sanity Check
-- Expected: source_count = dim_count
-- Failure: row count variance > 5%
SELECT
    (SELECT COUNT(*)
     FROM instacart.instacart_clean.products_clean) AS source_count,

    (SELECT COUNT(*)
     FROM instacart.instacart_gold.dim_products) AS dim_count;


-- Diagnostics (run if a check fails)
SELECT *
FROM instacart.instacart_gold.dim_products
WHERE product_id IS NULL
   OR product_name IS NULL
   OR TRIM(product_name) = '';


/*
Automation Recommendation

Preferred Tool:
- dbt

Command:
dbt test --select dim_products

Alternatives:
- Great Expectations
- Custom SQL validation scripts executed before gold promotion

Suggested Thresholds:
- Duplicate PKs: 0
- Orphan FKs: 0
- Null IDs: 0
- Null/Blank Names: 0
- Row Count Variance: <= 5%

Promotion Rule:
- Promote to gold only if all checks pass.
*/