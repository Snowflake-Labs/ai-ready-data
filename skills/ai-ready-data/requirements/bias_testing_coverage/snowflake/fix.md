# Fix: bias_testing_coverage

Create bias-testing tags and apply them to tables that have been evaluated.

## Context

This is a two-step process: first create the tag (if it doesn't exist), then apply it to tables that have undergone bias testing. The tag is a governance signal — apply it only after actual bias testing has been performed externally.

Before creating the tag, check if it already exists:

```sql
SHOW TAGS LIKE '{{ tag_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip tag creation.

## Fix: Create the bias testing tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

## Fix: Apply the tag to a tested table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}'
```
