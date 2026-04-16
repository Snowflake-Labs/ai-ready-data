# Fix: license_compliance

Fraction of externally sourced datasets with documented and valid usage licenses permitting AI training.

## Context

Two remediation steps: first create the license tag (if it does not already exist), then apply it to the target table.

`account_usage.tag_references` has approximately 2-hour latency for new tags — the check and diagnostic queries may not reflect changes immediately after tagging.

## Fix: Create the license tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

## Fix: Apply the license tag to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}'
```
