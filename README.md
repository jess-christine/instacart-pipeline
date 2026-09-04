# 🛒 Instacart Data Warehouse and Pipeline

> Turning raw grocery-order data into clean, reliable, and analytics-ready Delta tables.

This collaborative project uses Databricks SQL, Delta Lake, Unity Catalog, and GitHub Actions to build an end-to-end data pipeline from the Instacart dataset. The design follows the Medallion Architecture and organizes the workflow into Bronze, Silver, Gold, Analytics, and Tests layers.

![Instacart pipeline architecture](src/images/Instacart_diagram.png)

## Project objective

The project transforms source CSV files into a dimensional data warehouse that supports product, order, time, department, aisle, and reorder analysis.

It demonstrates:

- End-to-end data engineering in Databricks
- Medallion Architecture
- Delta table creation and incremental `MERGE` operations
- Data cleaning, standardization, and integration
- A Gold-layer star schema for reporting
- Automated data-quality checks
- Development and production CI/CD deployment

## Tools used

- Databricks SQL
- Delta Lake
- Unity Catalog
- Databricks SQL Warehouse
- GitHub and GitHub Actions
- SQL notebooks
- Draw.io

## Data pipeline

The pipeline follows this order:

```text
Source Files → Bronze → Silver → Gold → Analytics → Tests
```

| Layer | Purpose |
|---|---|
| **Source** | Original Instacart CSV files stored in a Databricks Volume. Source data is not committed to GitHub. |
| **Bronze** | Ingests source records into raw Delta tables with ingestion metadata. |
| **Silver** | Cleans, casts, standardizes, validates, deduplicates, and combines related datasets. |
| **Gold** | Builds the fact table and dimension tables used for analysis. |
| **Analytics** | Contains reusable business views and notebook queries for reporting questions. |
| **Tests** | Validates source data, cleaned data, Gold relationships, business results, and the release quality gate. |

Each layer has one responsibility. Preview queries and validation logic are kept separate from the production transformation files.

## Gold data model

The Gold layer uses a star schema centered on `fact_order_items`.

### Fact table

- `fact_order_items`

One row represents one product recorded within one customer order.

Important columns include:

- `order_id`
- `product_id`
- `timekey`
- `department_id`
- `aisle_id`
- `add_to_cart_order`
- `reordered`

The fact table uses `(order_id, product_id)` as its business key.

### Dimension tables

- `dim_order` — order and customer-level attributes
- `dim_order_time` — day and hour attributes
- `dim_products` — product, aisle, and department attributes

### Relationships

| Dimension key | Fact foreign key | Relationship |
|---|---|---|
| `dim_order.order_id` | `fact_order_items.order_id` | One order to many products |
| `dim_products.product_id` | `fact_order_items.product_id` | One product to many order records |
| `dim_order_time.order_time_key` | `fact_order_items.timekey` | One time record to many order records |

See the complete [star schema](docs/star_schema.md) and [data dictionary](docs/data_dictionary.md).

## Analytics

The analytics layer contains:

- `business_views.sql` for reusable reporting views
- `Business Questions.ipynb` for exploratory and business-focused analysis

The project supports questions such as:

- Which products and departments are ordered most often?
- Which days and hours have the highest order activity?
- Which products are frequently reordered?
- Which products are added early in an order?
- How does product behavior differ across departments and aisles?

Analytics files contain the final business queries. Data-quality validation remains in the `tests/` directory.

## Repository structure

```text
instacart-pipeline/
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       └── ci-cd.yml
├── docs/
│   ├── architecture_diagram.md
│   ├── assumptions.md
│   ├── data_dictionary.md
│   └── star_schema.md
├── ops/
│   └── instacart_job.json
├── presentation/
│   └── Presentation_notes.ipynb
├── scripts/
│   ├── ci_validate.py
│   └── deploy_databricks_job.sh
├── src/
│   ├── images/
│   │   └── Instacart_diagram.png
│   └── sql/
│       ├── 00_setup/          # Catalog, schemas, and source inspection
│       ├── 01_bronze_ingest/  # Raw Delta ingestion
│       ├── 02_silver_clean/   # Cleaning and integration
│       ├── 03_gold_model/     # Dimensions and fact table
│       └── 05_analytics/      # Views and business questions
├── tests/
│   ├── 01_source_checks.sql
│   ├── 02_clean_checks.sql
│   ├── 03_mart_checks.sql
│   ├── 04_business_query_checks.sql
│   └── 99_cicd_quality_gate.sql
└── README.md
```

## Run the pipeline

Run the layers in this order:

1. `src/sql/00_setup`
2. `src/sql/01_bronze_ingest`
3. `src/sql/02_silver_clean`
4. `src/sql/03_gold_model`
5. `src/sql/05_analytics`
6. `tests/`

The Databricks job in `ops/instacart_job.json` runs the setup, Bronze, Silver, Gold, and release quality-gate tasks in dependency order.

Before running ingestion, make sure the source CSV files are available at the configured Databricks Volume path.

## Incremental and rerun behavior

The pipeline is designed to be safe to rerun:

- Bronze tables use `CREATE TABLE IF NOT EXISTS`, so existing raw tables are not recreated.
- Silver order tables use `MERGE` on `order_id`.
- The Gold fact table uses `MERGE` on `(order_id, product_id)`.
- Duplicate source matches are reduced to one deterministic record before the fact-table merge.
- Existing records are updated and new business keys are inserted.

Because the current source is a fixed set of CSV files read from a Volume, this is currently an idempotent and repeatable pipeline, not a complete file-level incremental ingestion design. A future production enhancement may use `COPY INTO` and a watermark/control Delta table to process only newly arrived files.

## Quality checks

The test files validate:

- Source file availability and row counts
- Required columns and data types
- Null and duplicate business keys
- Valid day, hour, and reorder values
- Referential integrity between facts and dimensions
- Required audit metadata
- Duplicate protection after reruns
- Business-query output consistency

The `99_cicd_quality_gate.sql` file is the final Databricks release check. The job fails when a required quality assertion does not pass.

## CI/CD automation

GitHub Actions validates and deploys the pipeline through separate development and production environments.

- Pull requests to `main` or `develop` run repository validation only.
- Pushes to `develop` deploy the exact commit to the `development` Databricks environment.
- Pushes to `main` deploy the exact commit to the `production` Databricks environment.
- The development job is named `instacart-pipeline-development`.
- The production job is named `instacart-pipeline-production`.
- The workflow validates SQL, notebooks, job references, repository size, credentials, destructive SQL, and deployment-script syntax.
- The Databricks job runs Bronze → Silver → Gold → release quality gate.
- Documentation-only changes do not start a Databricks compute run.
- Production deployments are serialized, while outdated pull-request checks can be canceled.

### Required GitHub configuration

Create these GitHub Environments:

- `development`
- `production`

Add the following secrets to each environment using environment-specific Databricks values:

- `DATABRICKS_HOST`
- `DATABRICKS_TOKEN`
- `DATABRICKS_WAREHOUSE_ID`

The secret values must not be stored in SQL files, notebooks, job manifests, or the README. Configure required reviewers on the `production` environment if production approval is required.

## Documentation

- [Architecture](docs/architecture_diagram.md)
- [Data dictionary](docs/data_dictionary.md)
- [Star schema](docs/star_schema.md)
- [Project assumptions](docs/assumptions.md)
- [Presentation notes](presentation/Presentation_notes.ipynb)

---

Built as a collaborative FTW Data Engineering project. View the repository's [contributors](https://github.com/ItsYangCoder/instacart-pipeline/graphs/contributors).
