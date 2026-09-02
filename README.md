# 🛒 Instacart Order Management Data Pipeline

## 📖 Table of Contents
- [Project Overview & Data Lineage](#project-overview--data-lineage)
- [Architectural Assumptions & Basis of Decisions](#architectural-assumptions--basis-of-decisions)
- [Pipeline Readiness Metrics](#pipeline-readiness-metrics)
- [Repository Structure](#repository-structure)
- [End-to-End Execution Guidelines](#end-to-end-execution-guidelines)

---

## 🏗️ Project Overview & Data Lineage
This project implements an automated, idempotent data pipeline on Databricks using SQL. It ingests raw retail transaction data and models it into a Star Schema optimized for downstream business intelligence. 

**Data Lineage Path:**
`Secured External Storage` ➔ `Bronze (Raw Delta)` ➔ `Silver (Conformed Delta)` ➔ `Gold (Star Schema)` ➔ `Databricks Lakeview Dashboard`

*(Note: The exact path for the data source is intentionally omitted from this documentation for security purposes and is managed via secure cluster configurations).*

---

## 🧠 Architectural Assumptions & Basis of Decisions

* **Design Principles:** The codebase strictly adheres to the principles of DRY (Do not Repeat Yourself), Keep it simple, and Separation of Concern (SoC).
* **Table Setup:** All table creation is completed entirely during the setup phase. This prevents breaking changes and eliminates the compute overhead associated with recreating tables.
* **Data Retention:** The pipeline explicitly avoids the `REPLACE` command to ensure historical data is retained for business tracking.
* **Schema Evolution:** Ingestion logic dynamically handles schema evolution to adapt when source columns are added, removed, or changed. An audit table tracks these structural shifts.
* **Traceability:** Every ingestion script includes metadata flagging columns (e.g., `_load_date`, `_batch_date`) to facilitate audit trailing and data quality checking.
* **Isolated Data Quality:** Data quality checks are separated from ingestion queries to prevent excessive resource utilization.
* **Production Analytics:** The analytics phase is strictly client-facing; all exploratory data analysis queries are excluded from this repository.

---

## ✅ Pipeline Readiness Metrics
To evaluate the deployment readiness of the pipeline, the following repeatable standards and metrics must be met before merging to `main`:

- [ ] **System Idempotency:** Executing the pipeline multiple times processes the data without duplicating records or crashing.
- [ ] **Data Integrity:** The Gold layer maintains 0 null values in Primary Keys and 100% Foreign Key referential integrity.
- [ ] **Audit Compliance:** 100% of rows in the Bronze and Silver layers contain valid `_load_date` and `_source_file` metadata timestamps.
- [ ] **Constraint Validation:** Execution of the validation suite yields 0 constraint violations before views are exposed to the dashboard.


## 🛠️ Known Data Quality Issue

Product CSV Parsing Issue

During the creation of `clean.products`, one raw record failed numeric casting because its product name contained embedded commas:

`Scotch Kids 5" Scissors, Blunted, Red`

The commas caused the raw CSV fields to become misaligned, placing `Blunted` under `aisle_id` and `Red` under `department_id`.

**Temporary resolution:**
Used `TRY_CAST` for numeric columns and excluded records with invalid `product_id`, `aisle_id`, or `department_id` values.

**Impact:**
One malformed product record (`product_id = 6816`) was excluded from the clean table.

**Recommended permanent fix:**
Update the Bronze ingestion configuration to correctly handle quoted product names containing commas, then reload the affected record.

---

## 🗂️ Repository Structure
The repository is modularized to divide the system into distinct, well-defined sections, ensuring maintainability and scalability.

```text
instacart/        
├── src/
│   ├── 00_setup/                          
│   │   ├── 01_init_schemas.sql            
│   │   ├── 02_create_tables.sql           
│   │   └── 03_create_audit_table.sql      
│   ├── 01_bronze_ingest/                  
│   │   ├── ingest_orders.sql              
│   │   ├── ingest_products.sql            
│   │   ├── ingest_aisles.sql              
│   │   ├── ingest_departments.sql         
│   │   ├── ingest_order_products_prior.sql 
│   │   └── ingest_order_products_train.sql 
│   ├── 02_silver_clean/                   
│   │   ├── clean_orders.sql               
│   │   └── clean_order_products.sql       
│   ├── 03_gold_model/                     
│   │   ├── dim_products.sql               
│   │   └── fact_order_items.sql           
│   ├── 04_validation/                     
│   │   └── data_quality_checks.sql        
│   └── 05_analytics/                      
│       └── business_views.sql             
├── docs/
│   ├── architecture_diagram.png           
│   └── data_dictionary.md
│   └── star_schema.md
│   └── assumptions.md
│   └── team_timeline.md                   
├── .gitignore                             
└── README.md
