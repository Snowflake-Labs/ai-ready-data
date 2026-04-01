# Fix: lineage_completeness

Remediation guidance for tables without documented lineage.

## Context

PostgreSQL tracks object-level dependencies automatically when views or materialized views reference tables. There is no DDL to manually register lineage. To improve lineage completeness:

1. **Create views to document transformation chains** — if a table is consumed by downstream processes (dashboards, ETL, ML pipelines), create a view that encodes the transformation logic. This registers the dependency in `pg_depend` and makes the lineage visible to the check.
2. **Add comments to document external lineage** — for tables whose lineage exists outside PostgreSQL (external ETL, data loaders), use `COMMENT ON TABLE` to document upstream sources and downstream consumers.
3. **Create materialized views for aggregation layers** — materialized views serve dual purposes: they improve query performance and they establish tracked dependency relationships.

## Remediation: Create a view to document lineage

```sql
CREATE VIEW {{ schema }}.{{ view_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
```

## Remediation: Add a comment to document external lineage

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS
'Upstream: {{ source_system }} | Pipeline: {{ pipeline_name }} | Consumers: {{ downstream_systems }}'
```

## Remediation: Create a materialized view

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ view_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
WITH DATA
```
