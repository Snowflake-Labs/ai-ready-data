# Fix: demographic_representation

Remediation steps to tag demographic columns so representation can be measured and documented.

## Context

Two-step process: first create the tag if it does not exist, then apply it to the relevant columns. Tags propagate to `account_usage.tag_references` with approximately 2-hour latency, so the check query will not reflect changes immediately. Demographic attributes are sensitive — handle with appropriate access controls.

### Create Tag

Creates a new tag in the target schema with allowed values and a descriptive comment. Skip this step if the tag already exists.

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

### Apply Column Tags

Sets the demographic tag on a specific column. Repeat for each column that contains demographic or protected-class data.

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
MODIFY COLUMN {{ column }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}'
```