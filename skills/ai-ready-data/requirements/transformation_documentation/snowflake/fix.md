# Fix: transformation_documentation

Remediation guidance for undocumented transformation objects.

## Context

Snowflake supports `COMMENT ON` for views, dynamic tables, and materialized views. A good transformation comment should describe the logic applied, the input sources, and the output columns or purpose. The check considers comments longer than 20 characters as documented.

There are no automated fixes — each transformation's comment must be authored by someone who understands the logic. Use the diagnostic query to identify which objects need documentation.

## Fix: Add a comment to a view

```sql
COMMENT ON VIEW {{ database }}.{{ schema }}.{{ table_name }} IS 'Describe transformation logic, input sources, and output purpose here.';
```

## Fix: Add a comment to a dynamic table

```sql
COMMENT ON DYNAMIC TABLE {{ database }}.{{ schema }}.{{ table_name }} IS 'Describe transformation logic, input sources, and output purpose here.';
```

## Fix: Add a comment to a materialized view

```sql
COMMENT ON MATERIALIZED VIEW {{ database }}.{{ schema }}.{{ table_name }} IS 'Describe transformation logic, input sources, and output purpose here.';
```
