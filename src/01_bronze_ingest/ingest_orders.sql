Purpose: Idempotent ingestion of orders raw files into bronze.

Instructions - what to put here:
1) Document the stage or storage location (S3/GCS/ADLS/local) and file naming pattern for orders files.
2) Provide platform-specific COPY/LOAD examples (Snowflake COPY INTO, Databricks COPY INTO, Postgres \copy) as commented templates.
3) Include idempotency controls: how to detect already-processed files (manifest table, processed_files tracking), checksums, and watermarking.
4) Add examples for error handling (ON_ERROR behavior) and schema validation steps before loading to silver.

Testing: Add steps to run a small sample file and verify counts and sample rows in bronze.orders_raw.
