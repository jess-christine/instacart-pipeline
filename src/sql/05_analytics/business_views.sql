Purpose: High-level views for BI/dashboard consumption.

Instructions - what to put here:
1) Define lightweight views that join gold.dimensions and facts, keeping heavy transforms out of views when possible.
2) Provide examples: orders_by_product, repeat_customer_metrics, cohort retention, and daily revenue rollups (if price data exists).
3) Include notes on view performance: materialize expensive views as tables if needed, and define refresh cadences.
4) Add documentation for expected consumers (dashboard names, sample queries, and intended SLAs).
