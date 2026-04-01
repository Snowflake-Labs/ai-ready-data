# Fix: lineage_completeness

Remediation guidance for tables without documented lineage.

## Context

PostgreSQL does not have automatic query-level lineage like Snowflake's `ACCESS_HISTORY`. Lineage must be established structurally by creating SQL objects (views, materialized views) that reference the source tables. This registers the dependency in `pg_depend` and makes the transformation chain discoverable.

To improve this score:

1. **Create views to document transformations** — if a table feeds a dashboard, report, or downstream model, create a view that encodes the transformation. This establishes a tracked lineage relationship.
2. **Create materialized views for heavy transformations** — materialized views both improve performance and establish lineage.
3. **Add comments to document external lineage** — for tables whose lineage is managed by external tools (Airflow, dbt, etc.), use `COMMENT ON TABLE` to document the upstream sources and transformation logic.

## Remediation: Create a view to establish lineage

```sql
CREATE VIEW {{ schema }}.{{ view_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
```

## Remediation: Create a materialized view

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ matview_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
```

## Remediation: Document external lineage via comment

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS
'Upstream: {{ source_system }} | Pipeline: {{ pipeline_name }} | Transforms: {{ description }}'
```
