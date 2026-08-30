File purpose: Create base schemas used by the pipeline: bronze (raw), silver (conformed), gold (analytics).

Instructions - what to put here:
1) Add CREATE SCHEMA statements appropriate for your target database (Snowflake, Postgres, Databricks, etc.).
2) Include comments describing purpose of each schema and recommended access controls.
3) Provide guidance on how/when to run this file (one-time init), and any prerequisites (roles, stages, storage setup).
4) Add examples for setting up file formats or external stages (S3/GCS) if applicable.

Operational note: Do not drop schemas in production — document any destructive steps clearly and require manual approval.
