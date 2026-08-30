Purpose: Conform and union order_products__train and order_products__prior into silver.order_products.

Instructions - what to put here:
1) Describe the union strategy, include adding a dataset_source column (train/prior) for lineage.
2) Provide typing rules for each column and sample expressions to convert raw payload values into typed columns.
3) Include deduplication rules and match keys (order_id + product_id + add_to_cart_order) and how to resolve conflicts.
4) Recommend validation checks: FK checks to silver.orders and silver.products and acceptable null thresholds.

Operational: Prefer MERGE for incremental updates and include an audit insert per batch.
