CREATE TABLE IF NOT EXISTS /Volumes/instacart/default/ftw_b12_de/week06/instacart_csv/departments.csv
USING DELTA
AS
SELECT *,
  current_timestamp() AS ingestion_timestamp,
  current_date() AS ingestion_date
FROM read_files('/Volumes/instacart/default/ftw_b12_de/week06/instacart_csv/aisles.csv');
