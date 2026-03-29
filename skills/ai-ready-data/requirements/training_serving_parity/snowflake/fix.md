# Fix: training_serving_parity

Remediation guidance for feature tables that lack training/serving parity.

## Context

Static base tables used as feature stores create skew risk: training pipelines read batch snapshots while serving pipelines may compute features differently or from stale data. Converting feature tables to dynamic tables ensures the same transformation logic drives both paths.

True parity verification requires comparing transformation logic across pipelines — this heuristic only checks whether feature tables are dynamic. A dynamic table that sources from a different transformation than the training pipeline still has a parity gap.

## Remediation: Convert a static feature table to a dynamic table

Replace the static base table with a dynamic table that materializes from the same transformation logic used during training.

```sql
CREATE OR REPLACE DYNAMIC TABLE {{ database }}.{{ schema }}.{{ table_name }}
    TARGET_LAG = '1 hour'
    WAREHOUSE = {{ warehouse }}
AS
    SELECT * FROM {{ source_query }};
```