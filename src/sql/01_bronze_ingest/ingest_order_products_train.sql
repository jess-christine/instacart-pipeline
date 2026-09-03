CREATE TABLE IF NOT EXISTS instacart.instacart_bronze.order_products_train_bronze
USING DELTA
AS
SELECT *,
  current_timestamp() AS ingestion_timestamp,
  current_date() AS ingestion_date
FROM read_files('/Volumes/instacart/default/ftw_b12_de/week06/instacart_csv/order_products__train.csv');