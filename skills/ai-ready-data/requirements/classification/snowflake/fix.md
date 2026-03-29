# Fix: classification

Create governance tags and apply them to tables and columns.

## Context

Classification is a three-step process: create the tag, apply it to tables, optionally apply it to columns. For thorough automated classification, delegate to the `sensitive-data-classification` skill which uses `SYSTEM$CLASSIFY`.

Before creating a tag, check if it already exists:

```sql
SHOW TAGS LIKE '{{ tag_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip tag creation.

`account_usage.tag_references` has approximately 2-hour latency — re-running the check immediately after tagging may not reflect the changes.

## Remediation: Create a governance tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

## Remediation: Apply tag to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ tag_name }} = '{{ tag_value }}'
```

## Remediation: Apply tag to a column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
MODIFY COLUMN {{ column }}
SET TAG {{ tag_name }} = '{{ tag_value }}'
```
