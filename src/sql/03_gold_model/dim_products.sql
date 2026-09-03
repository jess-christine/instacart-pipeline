
-- Create DimProducts
CREATE TABLE IF NOT EXISTS instacart.instacart_gold.dim_products AS

SELECT
    p.product_id,
    INITCAP(TRIM(p.product_name)) AS product_name,

    a.aisle_id,
    a.aisle_name AS aisle,

    d.department_id,
    d.department AS department

FROM instacart.instacart_silver.products_silver p

LEFT JOIN instacart.instacart_silver.aisles_silver a
    ON p.aisle_id = a.aisle_id

LEFT JOIN instacart.instacart_silver.departments_silver d
    ON p.department_id = d.department_id;