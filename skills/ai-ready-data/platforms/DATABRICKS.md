# Databricks

Databricks support uses Unity Catalog for metadata, governance, and lineage. Pilot implementations exist for 3 requirements (`semantic_documentation`, `classification`, `lineage_completeness`).

## Capabilities

- Native column masking via Unity Catalog
- Row access policies (row filters)
- Vector search indexes via Mosaic AI Vector Search
- Lineage via `system.access.table_lineage`
- Governance tags via Unity Catalog tags (`information_schema.table_tags`, `column_tags`)
- Full SQL-based check execution

## Not Supported

- Semantic views (no Databricks equivalent — use column/table comments for documentation)
- `account_usage` equivalent (Snowflake-specific)
- Change tracking introspection (no direct equivalent to Snowflake change tracking / streams)

## SQL Dialect

- Use `CAST(x AS DOUBLE)` instead of `x::FLOAT`.
- Use `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` instead of `COUNT_IF()` if targeting older runtimes. Recent Databricks SQL supports `COUNT_IF`.
- `NULLIF()` works the same as Snowflake.
- `INTERVAL` syntax: `CURRENT_TIMESTAMP() - INTERVAL 30 DAYS` (not `DATEADD`).

## Metadata Access

- Unity Catalog `information_schema` provides tables, columns, constraints, tags.
- `system.access.table_lineage` provides table-level lineage (requires Unity Catalog enabled).
- `information_schema.table_tags` and `information_schema.column_tags` for governance tags.
- Metadata visibility depends on the executing principal's Unity Catalog permissions.

## Required Permissions

- USE CATALOG on target catalog
- USE SCHEMA on target schema
- SELECT on target tables
- Access to `system.access` schemas for lineage queries
