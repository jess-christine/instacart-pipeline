-- src/00_setup/02_create_tables.sql
-- DDL templates for Bronze/Silver/Gold tables. Adapt types/partitions to your environment.

-- Bronze (raw) tables: keep schema flexible to allow COPY INTO mergeSchema
CREATE TABLE IF NOT EXISTS instacart_bronze.orders_raw (
  -- If COPY INTO produces columns, replace with concrete columns
  raw_line STRING,
  _load_date TIMESTAMP,
  _batch_date DATE,
  _source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS instacart_bronze.products_raw (
  raw_line STRING,
  _load_date TIMESTAMP,
  _batch_date DATE,
  _source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS instacart_bronze.aisles_raw (raw_line STRING, _load_date TIMESTAMP, _batch_date DATE, _source_file STRING) USING DELTA;
CREATE TABLE IF NOT EXISTS instacart_bronze.departments_raw (raw_line STRING, _load_date TIMESTAMP, _batch_date DATE, _source_file STRING) USING DELTA;
CREATE TABLE IF NOT EXISTS instacart_bronze.order_products_prior_raw (raw_line STRING, _load_date TIMESTAMP, _batch_date DATE, _source_file STRING) USING DELTA;
CREATE TABLE IF NOT EXISTS instacart_bronze.order_products_train_raw (raw_line STRING, _load_date TIMESTAMP, _batch_date DATE, _source_file STRING) USING DELTA;

-- Silver (typed, conformed) tables -- examples with audit columns
CREATE TABLE IF NOT EXISTS instacart_silver.orders (
  order_id BIGINT,
  user_id BIGINT,
  order_number INT,
  order_dow INT,
  order_hour_of_day INT,
  days_since_prior_order DOUBLE,
  is_first_order BOOLEAN,
  _load_date TIMESTAMP,
  _batch_date DATE,
  _source_file STRING
) USING DELTA PARTITIONED BY (_batch_date);

CREATE TABLE IF NOT EXISTS instacart_silver.products (
  product_id BIGINT,
  product_name STRING,
  aisle_id BIGINT,
  department_id BIGINT,
  _load_date TIMESTAMP,
  _batch_date DATE,
  _source_file STRING
) USING DELTA;

CREATE TABLE IF NOT EXISTS instacart_silver.order_products (
  order_id BIGINT,
  product_id BIGINT,
  add_to_cart_order INT,
  reordered BOOLEAN,
  dataset_source STRING,
  _load_date TIMESTAMP,
  _batch_date DATE,
  _source_file STRING
) USING DELTA PARTITIONED BY (_batch_date);

-- Gold: dimensional examples
CREATE TABLE IF NOT EXISTS instacart_gold.dim_products (
  product_sk BIGINT,
  product_id BIGINT,
  product_name STRING,
  aisle_id BIGINT,
  department_id BIGINT,
  effective_from TIMESTAMP,
  effective_to TIMESTAMP,
  is_current BOOLEAN
) USING DELTA;

CREATE TABLE IF NOT EXISTS instacart_gold.fact_order_items (
  order_id BIGINT,
  order_date DATE,
  product_sk BIGINT,
  quantity INT,
  price DECIMAL(10,2)
) USING DELTA PARTITIONED BY (order_date);
