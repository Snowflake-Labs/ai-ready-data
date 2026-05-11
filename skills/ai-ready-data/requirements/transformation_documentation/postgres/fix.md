# Fix: transformation_documentation

Remediation guidance for undocumented transformation objects.

## Context

PostgreSQL supports `COMMENT ON` for views, materialized views, functions, and procedures. A good transformation comment should describe the logic applied, the input sources, and the output columns or purpose. The check considers comments longer than 20 characters as documented.

There are no automated fixes — each transformation's comment must be authored by someone who understands the logic. Use the diagnostic query to identify which objects need documentation.

PostgreSQL does not have Snowflake's "dynamic tables." The closest equivalents are materialized views (with scheduled refresh via `pg_cron` or similar) or functions.

## Remediation: Add a comment to a view

```sql
COMMENT ON VIEW {{ schema }}.{{ object_name }} IS 'Describe transformation logic, input sources, and output purpose here.';
```

## Remediation: Add a comment to a materialized view

```sql
COMMENT ON MATERIALIZED VIEW {{ schema }}.{{ object_name }} IS 'Describe transformation logic, input sources, and output purpose here.';
```

## Remediation: Add a comment to a function

```sql
COMMENT ON FUNCTION {{ schema }}.{{ object_name }}({{ arg_types }}) IS 'Describe transformation logic, input sources, and output purpose here.';
```

## Remediation: Add a comment to a procedure

```sql
COMMENT ON PROCEDURE {{ schema }}.{{ object_name }}({{ arg_types }}) IS 'Describe transformation logic, input sources, and output purpose here.';
```
