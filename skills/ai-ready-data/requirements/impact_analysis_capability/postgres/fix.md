# Fix: impact_analysis_capability

Remediation guidance for tables without tracked downstream dependents.

## Context

Impact analysis capability depends on downstream objects (views, materialized views, etc.) referencing base tables. PostgreSQL tracks these dependencies automatically in `pg_depend`. There is no DDL to manually register an impact relationship.

To improve this score:

1. **Create views to formalize dependencies** — if a table is consumed by dashboards, reports, or pipelines, create a view that encodes the access pattern. This registers the dependency and enables automatic impact analysis.
2. **Create materialized views for aggregation layers** — materialized views both improve performance and establish tracked dependency relationships.
3. **Add comments to document external consumers** — for tables consumed by external systems, use `COMMENT ON TABLE` to document the downstream impact chain so it can be reviewed manually before schema changes.

## Remediation: Create a view to establish a tracked dependency

```sql
CREATE VIEW {{ schema }}.{{ view_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
```

## Remediation: Document external consumers via comment

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS
'Downstream consumers: {{ consumer_list }}'
```
