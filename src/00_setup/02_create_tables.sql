File purpose: Define canonical tables for bronze, silver, and gold layers.

Instructions - what to put here:
1) Define raw (bronze) tables to store unmodified payloads and source metadata (file name, ingestion timestamp).
2) Define conformed (silver) tables with typed columns, null handling, and any staging tables for incremental processing.
3) Define gold dimensional tables and fact tables with primary keys and partitioning/clustering strategies.
4) Add comments about data types and platform-specific storage options (e.g., file formats, clustering keys, micro-partitions).
5) Include explicit guidance: downstream transforms must not use CREATE OR REPLACE for these base tables — prefer ALTER for schema changes.

Testing: Include simple SELECT COUNT(*) queries and sample data checks to validate table creation.
