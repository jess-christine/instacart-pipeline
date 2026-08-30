Purpose: Contain isolated assertions and checks used as quality gates before promoting to gold.

Instructions - what to put here:
1) List the required data quality checks (PK uniqueness, FK referential integrity, null-rate thresholds, row-count sanity checks).
2) For each check, provide the SQL query to assert the condition and the failure criteria.
3) Describe how failures should be handled (alerting, blocking promotion, creating issues with example diagnostics).
4) Recommend integration with a test harness or DQ tool (dbt tests, Great Expectations, or custom scripts) and show example invocation steps.

Operational: Include sample thresholds and recommendations for acceptable error rates and SLA for fixes.
