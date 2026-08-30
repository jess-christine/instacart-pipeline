Purpose: Transform bronze.orders_raw -> silver.orders (type conversions and canonicalization).

Instructions - what to put here:
1) Describe the expected raw payload format (JSON fields or CSV columns) and sample extraction expressions.
2) Add step-by-step transformation pseudocode: sampling, CAST/TRY_CAST rules, null handling, default values, and deduplication strategy.
3) Provide examples of staging/temporary tables and MERGE patterns to support idempotent incremental updates.
4) Include test queries to validate counts, key distributions, and sample rows after transformation.

Notes: Be explicit about handling timezone conversion and timestamp normalization.
