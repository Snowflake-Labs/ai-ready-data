# Fix: impact_analysis_capability

Remediation guidance for enabling downstream impact analysis.

## Context

Impact analysis capability depends on downstream objects (views, materialized views, functions) referencing the base tables. PostgreSQL's `pg_depend` catalog tracks these relationships automatically when DDL is executed. There is no way to manually register an impact relationship.

To improve this score:

1. **Create views or materialized views** — defining a view over a table establishes a tracked dependency. This is the most direct way to ensure that `pg_depend` can enumerate downstream impact.
2. **Use `pg_depend` queries** — once dependencies exist, tools and scripts can query `pg_depend` to build impact analysis reports before applying schema changes.
3. **Document external consumers** — for tables consumed by application code or external tools, use `COMMENT ON` to record downstream consumers that cannot be tracked via DDL.

## Remediation: Create a view to establish a tracked dependency

```sql
CREATE VIEW {{ schema }}.{{ asset }}_v AS
SELECT * FROM {{ schema }}.{{ asset }};
```

## Remediation: Document external downstream consumers

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'Downstream consumers: <app_name>, <dashboard_name>, <pipeline_name>';
```
