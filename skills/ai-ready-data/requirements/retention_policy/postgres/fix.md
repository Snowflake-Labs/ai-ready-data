# Fix: retention_policy

Define retention schedules via comments or partitioning infrastructure.

## Context

PostgreSQL has no native retention tagging like Snowflake. Two remediation paths are available:

1. **Structured comments** — add a table comment documenting the retention policy. The check looks for keywords like `retention`, `ttl`, `expire`, `purge`, `archive`, `lifecycle`. This documents intent but does not enforce deletion.
2. **Range partitioning** — set up range-based partitioning on a timestamp column. This enables actual lifecycle management by allowing old partitions to be detached and dropped. This is the stronger approach as it provides both documentation (via structure) and enforcement (via partition maintenance).

The comment should only be applied after the organization has determined the appropriate retention period. Applying a comment without a real retention determination creates a false compliance signal.

## Remediation: Add retention comment

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS
    '[retention: {{ retention_days }} days] {{ additional_description }}';
```

## Remediation: Create a range-partitioned table for lifecycle management

```sql
CREATE TABLE {{ schema }}.{{ asset }} (
    {{ column_definitions }},
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);
```

## Remediation: Create partitions for time ranges

```sql
CREATE TABLE {{ schema }}.{{ asset }}_{{ partition_suffix }}
    PARTITION OF {{ schema }}.{{ asset }}
    FOR VALUES FROM ('{{ start_date }}') TO ('{{ end_date }}');
```

## Remediation: Drop an expired partition

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    DETACH PARTITION {{ schema }}.{{ asset }}_{{ partition_suffix }};
DROP TABLE {{ schema }}.{{ asset }}_{{ partition_suffix }};
```
