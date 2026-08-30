File purpose: Audit table(s) to track schema changes, deployments, and pipeline runs.

Instructions - what to put here:
1) Create a schema_evolution (or equivalent) table that records who changed what, when, and why (object_type, object_name, description, version_tag).
2) Optionally add pipeline_run table to capture ingestion runs: run_id, start_time, end_time, files_processed, rows_ingested, status.
3) Provide example INSERT statements to log migrations and pipeline runs.
4) Describe the expected usage pattern: insert on each deployment, include CI hooks to write run metadata.

Operational note: Keep audit data immutable; do not backfill without documentation and version_tagging.
