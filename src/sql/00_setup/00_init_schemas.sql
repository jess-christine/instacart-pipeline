CREATE CATALOG IF NOT EXISTS instacart;

USE CATALOG instacart;

-- Raw tables loaded from the original CSV files.
CREATE SCHEMA IF NOT EXISTS instacart_raw;

-- Cleaned and standardized tables.
CREATE SCHEMA IF NOT EXISTS instacart_clean;

-- Dimension and fact tables.
CREATE SCHEMA IF NOT EXISTS instacart_mart;

-- Data-quality results and invalid records.
CREATE SCHEMA IF NOT EXISTS instacart_quality;


-- Check that the project schemas are available.
SHOW SCHEMAS IN instacart;
