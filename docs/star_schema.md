# Star Schema Design

## Overview

This document describes the Gold-layer dimensional model used in the Instacart Medallion Data Pipeline.

The Gold layer was designed using a star schema to support analytics, reporting, and business intelligence use cases.

The model separates descriptive business entities into dimension tables and transactional activity into a central fact table, providing a structure that is easy to query and scalable for future analytical requirements.

Related architecture documentation:

```text
docs/architecture_diagram.png
```

---

## Star Schema Diagram

The diagram below shows the Gold-layer dimensional model used in this project.

![Instacart pipeline](./src/images/instacart_diagram.png)

Figure: Gold-layer star schema consisting of dimension tables and a central fact table.

Source file:

```text
docs/images/Instacart_diagram.png
```

---

# Fact Table

## fact_order_items

### Description

Central fact table containing product purchases made within customer orders.

### Grain

One row per product purchased within an order.

### Primary Key

```text
(order_id, product_id)
```

### Foreign Keys

```text
order_id  → dim_order.order_id

product_id → dim_products.product_id

timekey → dim_order_time.order_time_key
```

### Measures

Available analytical measures include:

- Total Orders
- Total Products Purchased
- Repeat Purchase Rate
- Average Basket Size
- Product Purchase Count
- Orders by Day
- Orders by Hour

### Fact Attributes

| Column |
|----------|
| order_id |
| product_id |
| timekey |
| department_id |
| aisle_id |
| add_to_cart_order |
| reordered |

---

# Dimension Tables

## dim_products

### Description

Product dimension containing product, aisle, and department information.

### Grain

One row per product.

### Primary Key

```text
product_id
```

### Attributes

```text
product_id
product_name
aisle_id
aisle_name
department_id
department_name
```

### Business Purpose

Provides product hierarchy information for:

- Product analysis
- Aisle analysis
- Department analysis
- Sales reporting

---

## dim_order

### Description

Order dimension containing order-level and customer-level attributes.

### Grain

One row per order.

### Primary Key

```text
order_id
```

### Attributes

```text
order_id
user_id
order_number
```

### Business Purpose

Provides order context for:

- Customer order history
- Order frequency analysis
- Customer behavior analysis

---

## dim_order_time

### Description

Time dimension for analyzing order patterns.

### Grain

One row per unique time combination.

### Primary Key

```text
order_time_key
```

### Attributes

```text
order_time_key
order_dow
day_name
order_hour_of_day
hour_label
time_of_day
is_weekend
is_current
```

### Business Purpose

Supports:

- Day-of-week analysis
- Hour-of-day analysis
- Peak ordering analysis
- Weekend vs weekday analysis

---

# Entity Relationship Design

## Relationship Definitions

### dim_order → fact_order_items

Relationship:

```text
1 : Many
```

Explanation:

One order can contain multiple products.

```text
dim_order.order_id
        │
        ▼
fact_order_items.order_id
```

---

### dim_products → fact_order_items

Relationship:

```text
1 : Many
```

Explanation:

One product can appear in many order transactions.

```text
dim_products.product_id
           │
           ▼
fact_order_items.product_id
```

---

### dim_order_time → fact_order_items

Relationship:

```text
1 : Many
```

Explanation:

One time dimension record can be associated with many order transactions.

```text
dim_order_time.order_time_key
              │
              ▼
fact_order_items.timekey
```

---

# Recommended Future Enhancements

## Add dim_user

### Current Situation

Customer attributes currently exist inside:

```text
dim_order
```

through:

```text
user_id
```

### Recommended Design

Create a dedicated customer dimension.

```text
dim_user
    │
    ▼
fact_order_items
```

### Proposed Structure

```text
user_key
user_id
first_order_number
latest_order_number
total_orders
customer_segment
is_current
```

### Benefits

- Better customer analytics
- Cleaner dimensional design
- Easier future expansion
- Supports customer profiling

---

## Add dim_date

### Current Situation

The Instacart dataset only provides:

```text
order_dow
order_hour_of_day
```

and does not provide calendar dates.

### Recommended Design

If future datasets contain transaction dates, create:

```text
dim_date
```

### Proposed Structure

```text
date_key
full_date
year
quarter
month
month_name
week
day
day_name
is_weekend
```

### Benefits

- Industry-standard dimensional model
- Better time-series analysis
- Easier dashboard development
- Supports period-over-period comparisons

---

# Natural Keys vs Surrogate Keys

## Natural Keys

A natural key originates from the source system.

Examples:

```text
product_id
order_id
user_id
aisle_id
department_id
```

### Advantages

- Already exists in source data
- Easy to understand
- No additional key generation

### Disadvantages

- Source system changes can impact downstream models
- May not support historical tracking well

---

## Surrogate Keys

A surrogate key is a generated business-independent identifier.

Examples:

```text
product_key
customer_key
date_key
order_time_key
```

### Advantages

- Independent of source systems
- Supports historical tracking
- Better for Slowly Changing Dimensions
- Common industry practice

### Disadvantages

- Additional ETL logic required
- Less intuitive for business users

---

## Recommended Approach

Current project:

```text
Natural Keys
```

Recommended future production model:

```text
Dimensions:
    Surrogate Keys

Fact Tables:
    Foreign Keys referencing surrogate keys

Source Identifiers:
    Retained as business keys
```

Example:

```text
product_key     ← surrogate key
product_id      ← business key
```

---

# Slowly Changing Dimension (SCD) Strategy Guidance

## Current Project

The project uses a simplified approach because the Instacart dataset is static.

Historical attribute tracking is not required.

---

## Recommended Production Approach

### Type 1 SCD

Overwrite existing values.

Example:

```text
Old:
department_name = Produce

New:
department_name = Fresh Produce
```

Result:

```text
Fresh Produce
```

No history retained.

### Best For

- Data corrections
- Typographical fixes
- Reference data maintenance

---

### Type 2 SCD

Create a new row when attributes change.

Example:

```text
product_key = 101
product_name = Organic Bananas
effective_date = 2025-01-01
end_date = 2025-06-30
```

New record:

```text
product_key = 102
product_name = Organic Bananas Premium
effective_date = 2025-07-01
end_date = NULL
```

History is preserved.

### Best For

- Customer dimensions
- Product dimensions
- Organizational hierarchies
- Historical reporting

---

### Recommended Future Usage

| Dimension | Recommended SCD |
|------------|------------|
| dim_products | Type 2 |
| dim_user | Type 2 |
| dim_date | Type 0 |
| dim_order_time | Type 0 |
| dim_departments | Type 1 |
| dim_aisles | Type 1 |

---

# Recommended Architecture Diagram Elements

Reference:

```text
docs/architecture_diagram.png
```

The architecture diagram should include:

## Data Lineage

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

## Model Layer

Display:

```text
dim_products
dim_order
dim_order_time

        │
        ▼

fact_order_items
```

## Relationship Labels

Show:

```text
1 : Many
```

between:

- dim_products → fact_order_items
- dim_order → fact_order_items
- dim_order_time → fact_order_items

## Data Quality Components

Include:

- Row Count Validation
- Duplicate Validation
- Null Checks
- Referential Integrity Checks

## Orchestration Components

Include:

- Bronze Processing Job
- Silver Processing Job
- Gold Processing Job
- Validation Job

## BI Components

Examples:

- Power BI
- Tableau
- SQL Analytics
- Reporting Dashboards

---

# Summary

The Gold layer uses a star schema centered around `fact_order_items`, supported by the dimensions `dim_products`, `dim_order`, and `dim_order_time`. The design prioritizes analytical simplicity, clear business definitions, and ease of reporting while remaining extensible for future additions such as `dim_user`, `dim_date`, surrogate keys, and Slowly Changing Dimension strategies.