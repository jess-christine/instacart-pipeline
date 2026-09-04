# Data Dictionary

## Document Information

| Field | Value |
|---------|---------|
| Project | Instacart Medallion Data Pipeline |
| Version | Refer to `audit.version_tag` |
| Last Updated | Update on every schema change |
| Architecture | Medallion Architecture (Bronze → Silver → Gold) |
| Purpose | Reference documentation for data structures, business definitions, and analytical calculations |

---

# Gold Layer Tables

## dim_products

### Description

Product dimension containing product, aisle, and department attributes.

### Grain

One row per product.

### Primary Key

```text
product_id
```

### Foreign Keys

None

### Columns

| Column | Type | Description | Sample Value |
|----------|----------|----------|----------|
| product_id | BIGINT | Unique product identifier | 13176 |
| product_name | STRING | Product name | Bag of Organic Bananas |
| aisle_id | INT | Associated aisle identifier | 24 |
| aisle_name | STRING | Aisle name | Fresh Fruits |
| department_id | INT | Associated department identifier | 4 |
| department_name | STRING | Department name | Produce |

---

## dim_order

### Description

Order dimension containing customer and order-level attributes.

### Grain

One row per order.

### Primary Key

```text
order_id
```

### Foreign Keys

None

### Columns

| Column | Type | Description | Sample Value |
|----------|----------|----------|----------|
| order_id | BIGINT | Unique order identifier | 2539329 |
| user_id | BIGINT | Customer identifier | 1 |
| order_number | INT | Sequential order number for customer | 5 |

---

## dim_order_time

### Description

Time dimension used for temporal analysis of orders.

### Grain

One row per unique day-of-week and hour combination.

### Primary Key

```text
order_time_key
```

### Foreign Keys

None

### Columns

| Column | Type | Description | Sample Value |
|----------|----------|----------|----------|
| order_time_key | BIGINT | Surrogate key representing order timing attributes | 312 |
| order_dow | INT | Day of week order was placed | 0 |
| day_name | STRING | Day name derived from order_dow | Sunday |
| order_hour_of_day | INT | Hour order was placed | 10 |
| hour_label | STRING/TIME | Formatted hour label | 10:00 |
| time_of_day | STRING | Time bucket classification | Morning |
| is_weekend | BOOLEAN | Indicates Saturday or Sunday | TRUE |
| is_current | BOOLEAN | Current record indicator | TRUE |

### Derived Logic

```sql
CASE
    WHEN order_hour_of_day BETWEEN 5 AND 11 THEN 'Morning'
    WHEN order_hour_of_day BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN order_hour_of_day BETWEEN 17 AND 20 THEN 'Evening'
    ELSE 'Night'
END
```

---

## fact_order_items

### Description

Fact table containing product purchases within orders.

### Grain

One row per product purchased within an order.

### Primary Key

Composite Key:

```text
(order_id, product_id)
```

### Foreign Keys

```text
order_id       → dim_order.order_id
product_id     → dim_products.product_id
timekey        → dim_order_time.order_time_key
```

### Columns

| Column | Type | Description | Sample Value |
|----------|----------|----------|----------|
| order_id | BIGINT | Order identifier | 2539329 |
| product_id | BIGINT | Purchased product identifier | 13176 |
| timekey | BIGINT | Reference to order time dimension | 312 |
| department_id | INT | Product department identifier | 4 |
| aisle_id | INT | Product aisle identifier | 24 |
| add_to_cart_order | INT | Sequence added to cart | 1 |
| reordered | BOOLEAN | Indicates previous purchase of product | TRUE |

---

# Silver Layer Tables

## clean_orders

### Description

Cleaned version of Instacart orders dataset.

### Grain

One row per order.

### Key

```text
order_id
```

### Columns

| Column | Type |
|----------|----------|
| order_id | BIGINT |
| user_id | BIGINT |
| eval_set | STRING |
| order_number | INT |
| order_dow | INT |
| order_hour_of_day | INT |
| days_since_prior_order | FLOAT |

---

## clean_products

### Description

Cleaned product master data.

### Grain

One row per product.

### Key

```text
product_id
```

### Columns

| Column | Type |
|----------|----------|
| product_id | BIGINT |
| product_name | STRING |
| aisle_id | INT |
| department_id | INT |

---

## clean_aisles

### Description

Cleaned aisle reference data.

### Grain

One row per aisle.

### Key

```text
aisle_id
```

### Columns

| Column | Type |
|----------|----------|
| aisle_id | INT |
| aisle_name | STRING |

---

## clean_departments

### Description

Cleaned department reference data.

### Grain

One row per department.

### Key

```text
department_id
```

### Columns

| Column | Type |
|----------|----------|
| department_id | INT |
| department_name | STRING |

---

## clean_order_products

### Description

Combined dataset created from:

```text
order_products__prior
+
order_products__train
```

### Grain

One row per product purchased within an order.

### Composite Key

```text
(order_id, product_id)
```

### Columns

| Column | Type |
|----------|----------|
| order_id | BIGINT |
| product_id | BIGINT |
| add_to_cart_order | INT |
| reordered | BOOLEAN |

---

## clean_order_merge

### Description

Integrated transaction dataset joining order attributes with purchased products.

### Grain

One row per purchased product per order.

### Composite Key

```text
(order_id, product_id)
```

### Sources

```text
clean_orders
      +
clean_order_products
```

### Columns

| Column | Type |
|----------|----------|
| order_id | BIGINT |
| user_id | BIGINT |
| product_id | BIGINT |
| order_number | INT |
| order_dow | INT |
| order_hour_of_day | INT |
| add_to_cart_order | INT |
| reordered | BOOLEAN |

---

# Bronze Layer Tables

## bronze_orders

Raw ingestion table for:

```text
orders.csv
```

---

## bronze_products

Raw ingestion table for:

```text
products.csv
```

---

## bronze_aisles

Raw ingestion table for:

```text
aisles.csv
```

---

## bronze_departments

Raw ingestion table for:

```text
departments.csv
```

---

## bronze_order_products_prior

Raw ingestion table for:

```text
order_products__prior.csv
```

---

## bronze_order_products_train

Raw ingestion table for:

```text
order_products__train.csv
```

---

# Derived Measures

## Repeat Purchase Rate

### Description

Percentage of purchased products marked as reordered.

### Formula

```sql
SUM(CASE WHEN reordered = TRUE THEN 1 ELSE 0 END)
/
COUNT(*)
```

### Business Meaning

Measures customer tendency to purchase products previously ordered.

---

## Total Orders

### Formula

```sql
COUNT(DISTINCT order_id)
```

### Business Meaning

Total number of orders placed.

---

## Total Customers

### Formula

```sql
COUNT(DISTINCT user_id)
```

### Business Meaning

Number of unique customers.

---

## Total Products Purchased

### Formula

```sql
COUNT(*)
```

### Business Meaning

Total product-level transactions.

---

## Average Basket Size

### Formula

```sql
COUNT(*)
/
COUNT(DISTINCT order_id)
```

### Business Meaning

Average number of products per order.

---

## Most Popular Products

### Formula

```sql
COUNT(order_id)
GROUP BY product_id
```

### Business Meaning

Identifies products purchased most frequently.

---

## Orders by Hour

### Formula

```sql
COUNT(DISTINCT order_id)
GROUP BY order_hour_of_day
```

### Business Meaning

Measures customer ordering patterns throughout the day.

---

## Orders by Day of Week

### Formula

```sql
COUNT(DISTINCT order_id)
GROUP BY order_dow
```

### Business Meaning

Measures ordering behavior across the week.

---

# Data Quality Rules

## Silver Layer

Validation checks include:

- Null checks on key columns
- Duplicate key detection
- Product reference validation
- Aisle reference validation
- Department reference validation
- Row count verification

---

## Gold Layer

Validation checks include:

- Fact-to-dimension referential integrity
- Duplicate business key checks
- Primary key uniqueness checks
- Row count reconciliation
- Model completeness verification

---

# Schema Change Management

## Versioning Requirements

Update this document whenever:

- New tables are added
- Existing tables are modified
