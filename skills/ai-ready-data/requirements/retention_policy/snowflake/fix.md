# Fix: retention_policy

Create retention tags and apply them to tables.

## Context

The tag should only be applied after the organisation has determined the appropriate retention period for data in each table. Applying a tag without a real retention determination creates a false compliance signal.

Before creating the tag, check if it already exists:

```sql
SHOW TAGS LIKE '{{ tag_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip tag creation.

`account_usage.tag_references` has approximately 2-hour latency — recently tagged tables may not appear yet. Note: `tag_references` has no `deleted` column — do not filter on it.

## Fix: Create the retention tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

## Fix: Apply retention tag to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}'
```
