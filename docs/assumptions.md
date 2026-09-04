# Assumptions

## Overview

This document records assumptions used throughout the Instacart Medallion Data Pipeline. These assumptions guide how source data is interpreted, transformed, validated, and modeled for analytics.

This document should be reviewed and updated whenever new datasets are onboarded, business rules change, or pipeline logic is modified.

---

## Business Assumptions

### Order Day Mapping

#### Assumption

```text
order_dow = 0
```

is interpreted as:

```text
Sunday
```

based on common industry and calendar conventions.

#### Impact if Violated

- Incorrect weekday reporting
- Incorrect weekend classification
- Misleading time-based analytics

#### Mitigation

- Verify day mappings against source documentation.
- Update the time dimension logic if a different convention is confirmed.

---

### Prior and Train Represent the Same Business Event

#### Assumption

The datasets

```text
order_products__prior
order_products__train
```

both represent products purchased within customer orders and can therefore be combined into a single transactional dataset.

#### Impact if Violated

- Incorrect purchase metrics
- Duplicate business logic
- Invalid transaction analysis

#### Mitigation

- Reassess Silver-layer integration logic if source definitions change.

---

### Test Orders Are Excluded From Reporting

#### Assumption

Rows where:

```text
eval_set = 'test'
```

are excluded from reporting because no product-level purchase records are provided.

#### Impact if Violated

- Incomplete transactions may be included
- Reporting metrics may become inaccurate

#### Mitigation

- Apply dataset filtering during transformation.
- Validate record counts against expected reporting datasets.

---

### add_to_cart_order Represents Product Sequence

#### Assumption

`add_to_cart_order` represents the recorded sequence of a product within a specific order.

It does not represent:

- Quantity purchased
- Exact cart-entry timestamp
- Customer purchase priority

#### Impact if Violated

- Basket analysis may be misleading
- Incorrect interpretation of customer behavior

#### Mitigation

- Use only for sequence-based analysis.
- Exclude from quantity-related calculations.

---

## Data Assumptions

### Product IDs Are Unique

#### Assumption

`product_id` uniquely identifies a product across the dataset.

Records containing missing or invalid product identifiers are excluded during data quality processing.

#### Impact if Violated

- Duplicate dimension records
- Incorrect product reporting
- Referential integrity failures

#### Mitigation

- Validate uniqueness of `product_id`.
- Exclude invalid records through Silver-layer validation checks.

---

### Order Day and Hour Values Follow Instacart Definitions

#### Assumption

The following ranges are expected:

```text
order_dow = 0–6
order_hour_of_day = 0–23
```

where:

```text
0 = Sunday
```

and `order_hour_of_day` follows a 24-hour clock.

#### Impact if Violated

- Incorrect time dimension generation
- Invalid time-based reporting
- Broken analytical aggregations

#### Mitigation

- Validate value ranges during transformation.
- Flag or reject records outside expected boundaries.

---

## Technical Assumptions

### Time Dimension Uses a Surrogate Key

#### Assumption

A surrogate key is created using:

```text
time_key = (order_dow * 100) + order_hour_of_day
```

Example:

```text
order_dow = 2
order_hour_of_day = 14

time_key = 214
```

The surrogate key is used to improve join efficiency and decouple the fact table from natural source attributes.

#### Impact if Violated

- Fact-to-dimension joins may fail
- Time dimension mappings may become inconsistent

#### Mitigation

- Regenerate the dimension using the documented key-generation logic.
- Validate uniqueness during model creation.

---

### Data Quality Rules Are Enforced

#### Assumption

The pipeline assumes:

- `add_to_cart_order` is a positive sequential integer
- `reordered` is a binary indicator (0 or 1)
- Missing `reordered` values are defaulted to 0
- Records missing required primary key values are excluded

#### Impact if Violated

- Validation failures
- Inaccurate reporting
- Broken joins

#### Mitigation

- Apply Silver-layer validation checks.
- Monitor data quality metrics and validation outputs.

---

### Silver Layer Contains Final Cleansing Logic

#### Assumption

All cleansing, standardization, integration, and correction activities occur in the Silver layer before data is promoted to Gold.

#### Impact if Violated

- Duplicate business logic
- Inconsistent reporting outputs
- Increased maintenance effort

#### Mitigation

- Centralize transformations in Silver.
- Keep Gold focused on dimensional modeling and analytics.

---

### Fact Table Keys Are Immutable

#### Assumption

The following fact table fields are treated as immutable:

```text
order_id
product_id
time_key
department_id
aisle_id
```

All corrections are assumed to have already been completed in the Silver layer and supporting dimensions.

#### Impact if Violated

- Broken dimensional relationships
- Inconsistent historical reporting
- Referential integrity issues

#### Mitigation

- Apply corrections upstream.
- Rebuild Gold-layer tables when source corrections occur.

---

### Liquid Clustering Supports Query Performance

#### Assumption

Liquid clustering is configured on:

```text
(order_id, product_id)
```

to improve downstream join performance with dimensional tables while avoiding the directory overhead associated with traditional partitioning.

#### Impact if Violated

- Slower joins
- Higher compute usage
- Reduced query efficiency

#### Mitigation

- Review clustering effectiveness periodically.
- Adjust clustering strategy if query patterns change.

---

### Audit Lineage Is Preserved

#### Assumption

Data lineage is maintained through audit fields:

```text
_load_date
_batch_date
dataset_source
```

#### Impact if Violated

- Reduced traceability
- Limited audit capability
- More difficult root-cause analysis

#### Mitigation

- Validate audit-column population during pipeline execution.
- Include lineage checks in validation procedures.
