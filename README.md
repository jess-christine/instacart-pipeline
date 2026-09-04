# 🛒 Instacart Data Pipeline

> Turning raw grocery-order data into clean, reliable, analytics-ready tables.

This team project uses **Databricks SQL** and **Delta Lake** to build an end-to-end data pipeline based on the Medallion Architecture.

![Instacart pipeline architecture](src/images/Instacart_diagram.png)

## 🔄 How the data moves

**Source files → Bronze → Silver → Gold → Analytics**

| Layer | Purpose |
|---|---|
| 🥉 **Bronze** | Ingests raw Instacart data and keeps source-level records |
| 🥈 **Silver** | Cleans, standardizes, validates, and combines related datasets |
| 🥇 **Gold** | Builds fact and dimension tables for business analysis |
| 📊 **Analytics** | Answers business questions through reusable SQL views and notebooks |

## 🎯 What this project demonstrates

- A structured **ETL pipeline** in Databricks
- **Delta tables** across Bronze, Silver, and Gold layers
- Clean and reusable **SQL transformations**
- A **star schema** for faster and simpler reporting
- Data-quality checks for nulls, duplicates, keys, and row counts
- Audit-friendly metadata and repeatable pipeline runs

## 🧱 Gold data model

The analytics layer is organized around:

- **Fact:** `fact_order_items`
- **Dimensions:** `dim_order`, `dim_order_time`, and `dim_products`

Together, these tables support questions such as:

- Which products and departments are ordered most?
- What days and hours have the highest ordering activity?
- How often do customers reorder products?

See the full [star schema](docs/star_schema.md) and [data dictionary](docs/data_dictionary.md).

## 📁 Repository guide

```text
instacart-pipeline/
├── src/
│   ├── sql/
│   │   ├── 00_setup/           # Schemas and source inspection
│   │   ├── 01_bronze_ingest/   # Raw data ingestion
│   │   ├── 02_silver_clean/    # Cleaning and standardization
│   │   ├── 03_gold_model/      # Fact and dimension tables
│   │   └── 05_analytics/       # Business views and analysis
│   └── images/                 # Project visuals
├── tests/                      # Source, clean, mart, and query checks
├── docs/                       # Architecture and model documentation
└── presentation/               # Presentation notes
```

## ▶️ Run the pipeline

Run the folders in this order:

1. `00_setup`
2. `01_bronze_ingest`
3. `02_silver_clean`
4. `03_gold_model`
5. `05_analytics`
6. `tests`

> Source paths are intentionally excluded from the repository. Configure them securely in Databricks before running ingestion.

## ✅ Quality checks

Before results are used for reporting, the tests verify:

- Primary keys are complete and unique
- Foreign keys match their dimension tables
- Required audit metadata is present
- Re-running the pipeline does not create duplicates
- Business queries return valid results

## ⚠️ Known data-quality note

One source record, `product_id = 6816`, contains commas inside the product name:

`Scotch Kids 5" Scissors, Blunted, Red`

The raw CSV was parsed into the wrong columns, so the record was temporarily excluded from the clean table using safe numeric casting. The permanent fix is to reload the source with correct quoted-field handling.

## 📚 Documentation

- [Architecture](docs/architecture_diagram.md)
- [Data dictionary](docs/data_dictionary.md)
- [Star schema](docs/star_schema.md)
- [Project assumptions](docs/assumptions.md)

---

Built as a collaborative **FTW Data Engineering** project. View the repository’s [contributors](https://github.com/ItsYangCoder/instacart-pipeline/graphs/contributors).
