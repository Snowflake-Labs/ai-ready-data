# Fix: purpose_limitation

Remediation queries for tables missing a declared AI processing purpose.

## Context

Tables without a purpose tag have no enforceable declaration of what AI processing is permitted. The remediation below creates the tag (if it does not exist) and applies it to the target table.

`account_usage.tag_references` has approximately 2-hour latency — tags will not appear in check/diagnostic results immediately after application.

## Fix: Create the purpose tag

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
```

## Fix: Apply the purpose tag to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ database }}.{{ schema }}.{{ tag_name }} = '{{ tag_value }}'
```