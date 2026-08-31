Purpose: Build slowly changing dimension (SCD) for products in gold.dim_products.

Instructions - what to put here:
1) Define the SCD type to implement (Type 1 overwrite vs Type 2 history) and rationale.
2) Provide MERGE/UPSERT pseudocode tailored to your SQL dialect, including surrogate key generation strategy.
3) Describe backfill approach for initial load and future change capture (CDC) integration if available.
4) Add examples for handling attribute normalization (product_name canonicalization) and dealing with missing aisle/department FK values.

Testing: Include queries to verify current active record per product_id and count of historical rows.
