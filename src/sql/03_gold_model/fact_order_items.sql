Purpose: Build fact table of order items for analytics and BI.

Instructions - what to put here:
1) Describe join logic to combine silver.order_products, silver.orders, and gold.dim_products (resolve product_key via product_id).
2) Provide MERGE/INSERT pseudocode for incremental population, surrogate key assignment, and idempotency controls.
3) Define partitioning and clustering strategy for fact table (by order_date, product_key) based on query patterns.
4) Note enrichment opportunities (price, promotions) and how to integrate them.

Validation: Add sample aggregation queries to validate totals against source counts.
