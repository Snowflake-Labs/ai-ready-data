# Fix: semantic_documentation

Remediation strategies for columns lacking machine-readable semantic descriptions.

## Context

PostgreSQL does not support Snowflake's semantic views. The only remediation path is adding column and table comments via `COMMENT ON`. Comments are free-form text stored in `pg_description` and retrievable via `col_description()` and `obj_description()`.

For structured semantic metadata beyond comments, consider external catalog tools (DataHub, OpenMetadata, Amundsen) that can layer machine-readable semantics on top of PostgreSQL.

A good column comment should describe the business meaning, expected values, and any constraints not captured by the schema itself. Aim for comments longer than 20 characters to pass the documentation threshold.

## Remediation: Add column comments

```sql
COMMENT ON COLUMN {{ schema }}.{{ asset }}.{{ column }} IS '{{ column_comment }}';
```

## Remediation: Add table comments

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS '{{ table_comment }}';
```
