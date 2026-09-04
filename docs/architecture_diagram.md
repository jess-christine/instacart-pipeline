# Architecture Diagram

## Architecture Diagram Placeholder

Create a visual architecture diagram that illustrates the complete data pipeline from source files to analytics-ready datasets.

### Diagram Requirements

The diagram should include:

#### Data Lineage

```text
Source Files
      │
      ▼
 Bronze Layer
      │
      ▼
 Silver Layer
      │
      ▼
 Gold Layer
      │
      ▼
 BI / Analytics
```

#### Source Layer

Show all raw Instacart source files:

- orders.csv
- products.csv
- aisles.csv
- departments.csv
- order_products__prior.csv
- order_products__train.csv

#### Bronze Layer

Show raw ingestion tables:

- bronze_orders
- bronze_products
- bronze_aisles
- bronze_departments
- bronze_order_products_prior
- bronze_order_products_train

Annotations:

- Raw data ingestion
- Minimal transformation
- Source preservation
- Traceability to original files

#### Silver Layer

Show cleaned and integrated tables:

- clean_orders
- clean_products
- clean_aisles
- clean_departments
- clean_order_products
- clean_order_merge

Annotations:

- Data cleaning
- Standardization
- Null handling
- Deduplication
- Data integration
- Validation checks

#### Gold Layer

Show dimensional model tables:

Dimensions:
- dim_products
- dim_aisles
- dim_departments
- dim_customers
- dim_orders

Fact:
- fact_order_products

Annotations:

- Star schema design
- Business-ready datasets
- Analytics optimization
- Reporting-ready structures

#### BI Layer

Examples:

- Power BI
- Tableau
- SQL Analytics
- Reporting Dashboards

#### Data Quality and Monitoring

Include validation and monitoring processes between layers:

- Row count validation
- Duplicate checks
- Null value checks
- Referential integrity checks
- Data quality monitoring

Show validations occurring between:

```text
Bronze → Silver
Silver → Gold
```

#### Orchestration

Include the pipeline execution sequence:

```text
Bronze Job
    │
    ▼
Silver Job
    │
    ▼
Gold Job
    │
    ▼
Validation Job
```

Annotations:

- Notebook execution sequence
- Layer dependencies
- Workflow orchestration
- Validation checkpoints

#### File Locations

Annotate each pipeline stage with its location:

```text
data/
    raw/

notebooks/
    bronze/
    silver/
    gold/

validation/

docs/
```

#### Deliverables

Export final diagram as:

```text
docs/architecture_diagram.png
```

Optional source diagram:

```text
design/architecture_diagram.drawio
```

---

# Architecture Decisions

## Overview

This document explains the architectural and modeling decisions made throughout the project.

The goal is to provide context for how the pipeline was designed and why certain implementation choices were made. These decisions are intended to improve maintainability, usability, and analytical value while keeping the solution aligned with the project requirements.

---

## Why Medallion Architecture Was Used

The pipeline was organized using Medallion Architecture, which separates data into Bronze, Silver, and Gold layers.

```text
Raw Files
    │
    ▼
 Bronze
    │
    ▼
 Silver
    │
    ▼
 Gold
```

### Decision

Separate raw, cleaned, and business-ready data into distinct layers.

### Rationale

Keeping each stage of processing isolated makes the pipeline easier to understand and maintain.

This approach allows:

- Raw data to remain unchanged
- Data quality rules to be applied in a dedicated layer
- Business models to remain independent of source system complexity

### Benefits

- Clear separation of responsibilities
- Easier troubleshooting
- Improved reproducibility
- Better scalability for future enhancements

---

## Why Bronze Tables Preserve Raw Data

The Bronze layer intentionally avoids business transformations.

### Decision

Load source files with minimal modification.

### Rationale

The source data should remain available in its original form.

Preserving raw data makes it possible to:

- Rebuild downstream layers
- Validate transformations
- Investigate data quality issues
- Compare transformed data with source records

### Benefits

- Improved traceability
- Simplified debugging
- Reproducible processing

---

## Why Prior and Train Datasets Were Combined

The Instacart dataset separates product purchases into two files:

```text
order_products__prior
order_products__train
```

### Decision

Combine both datasets into a single Silver-layer table.

```text
order_products__prior
           +
order_products__train
           │
           ▼
clean_order_products
```

### Rationale

The original dataset was designed for a machine learning competition.

In that context:

- Prior represents historical customer purchases
- Train represents a customer's next labeled purchase

For analytics, however, both datasets describe the same business event:

> A customer purchased a product within an order.

The distinction between prior and train is important for predictive modeling but not necessary for reporting and business analysis.

### Benefits

- Creates a single source of truth for product purchases
- Reduces duplicate transformation logic
- Simplifies downstream processing
- Makes dimensional modeling easier

---

## Why the Test Dataset Was Not Included

### Decision

Exclude the test dataset from the pipeline.

### Rationale

The Instacart dataset does not provide product-level purchase records for test orders.

Because the project focuses on transactional analysis, the required product-level information is unavailable.

Including incomplete orders would add complexity without contributing meaningful analytical value.

### Benefits

- Maintains dataset consistency
- Avoids incomplete transaction records
- Simplifies modeling logic

---

## Why clean_order_merge Was Created

Order information and product-purchase information exist in separate datasets.

### Decision

Create an integrated Silver-layer transaction table.

```text
clean_orders
       +
clean_order_products
       │
       ▼
clean_order_merge
```

### Rationale

Several business questions require attributes from both datasets.

Examples include:

- Product purchases by hour of day
- Product purchases by customer
- Reorder behavior by product
- Product demand over time

Without integration, the same joins would need to be repeated throughout the Gold layer.

By combining the datasets once in Silver, the integration logic becomes centralized and reusable.

### Benefits

- Reduces duplication
- Simplifies Gold-layer development
- Creates a reusable transactional dataset
- Improves maintainability

---

## Why Business Logic Was Centralized in Silver

### Decision

Perform cleansing, standardization, and integration in Silver rather than Gold.

### Rationale

The purpose of Silver is to prepare data for analytical consumption.

The purpose of Gold is to model business entities and metrics.

Separating these responsibilities keeps the architecture easier to understand and maintain.

### Benefits

- Cleaner Gold layer logic
- Easier testing
- Better separation of concerns
- More reusable datasets

---

## Why CREATE TABLE IF NOT EXISTS Was Used Throughout the Pipeline

### Decision

Use `CREATE TABLE IF NOT EXISTS` to create all Silver and Gold tables, followed by `INSERT INTO` statements to populate data.

### Rationale

A consistent table creation approach was used throughout the project.

Rather than recreating tables during execution, the pipeline first establishes the required table structures and then loads transformed data into those tables.

This pattern makes the workflow easier to follow, particularly in a learning environment where transformation logic is frequently inspected, validated, and refined.

Using the same implementation approach across both Silver and Gold layers also improves consistency and maintainability while making debugging simpler.

### Benefits

- Consistent implementation across all layers
- Easier debugging and troubleshooting
- Clear separation of table creation and data loading
- Supports validation of intermediate datasets
- Improved readability and maintainability
- Simpler development and testing workflow

---

## Why a Full Refresh Strategy Was Appropriate

### Decision

Reload Gold-layer tables from the latest Silver-layer data during execution.

### Rationale

The Instacart dataset is static and this project focuses on demonstrating core data engineering concepts rather than supporting continuously arriving production data.

Because the source data does not change, reloading the Gold layer from Silver ensures that all dimensional and fact tables reflect the latest transformation logic.

A full refresh approach prioritizes simplicity, reproducibility, and ease of validation over incremental processing complexity.

This makes the pipeline easier to understand, test, and maintain within the scope of the project.

### Benefits

- Predictable and repeatable results
- Easier validation and testing
- Simpler pipeline design
- Reduced implementation complexity
- Well suited for a static analytical dataset

---

## Why a Star Schema Was Used in Gold

### Decision

Model business-ready data using a star schema composed of dimension and fact tables.

### Rationale

The primary objective of the Gold layer is to support analytical queries and reporting.

A star schema organizes descriptive attributes into dimension tables while storing transactional activity in a central fact table.

This structure is widely used in analytics because it simplifies business analysis and reduces query complexity.

In this project:

Dimensions:

- dim_products
- dim_aisles
- dim_departments
- dim_customers
- dim_orders

Fact:

- fact_order_products

### Benefits

- Simplifies reporting queries
- Improves analytical usability
- Creates clear business entities
- Reduces repetitive joins
- Supports future dashboarding and BI use cases

---

## Why Data Validation Was Included

### Decision

Implement validation checks throughout the pipeline to verify data quality and model integrity.

### Rationale

Data quality is a critical aspect of data engineering.

Validation ensures that transformations produce accurate and reliable outputs before data moves to downstream layers.

Validation checks were performed to confirm:

- Expected row counts
- Uniqueness of business keys
- Referential integrity
- Acceptable null rates
- Successful table population

### Benefits

- Improves trust in analytical outputs
- Detects transformation issues early
- Supports reproducibility
- Helps maintain data integrity across layers

---