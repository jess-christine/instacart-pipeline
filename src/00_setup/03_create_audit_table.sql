-- src/00_setup/03_create_audit_table.sql
-- Audit and pipeline run metadata tables

CREATE TABLE IF NOT EXISTS instacart_audit.schema_evolution (
  change_id STRING,
  change_ts TIMESTAMP,
  description STRING,
  version_tag STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS instacart_audit.pipeline_runs (
  run_id STRING,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status STRING,
  files_processed INT,
  rows_ingested BIGINT,
  error_text STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS instacart_audit.processed_files (
  file_name STRING,
  checksum STRING,
  batch_id STRING,
  processed_at TIMESTAMP,
  status STRING,
  metadata MAP<STRING,STRING>
) USING DELTA;

-- Usage examples (pseudocode):
-- INSERT INTO instacart_audit.processed_files VALUES ('orders.csv','abc123','2023-01-01-1',current_timestamp(),'processing', map('source','s3://...'));
-- On success UPDATE instacart_audit.processed_files SET status='done' WHERE file_name='...';
