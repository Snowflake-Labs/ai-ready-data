# Fix: classification

Apply governance classification to tables and columns via security labels or structured comments.

## Context

PostgreSQL has no native tagging system like Snowflake. Classification can be achieved through two mechanisms:

1. **Security labels** (preferred) — requires a label provider to be loaded via `shared_preload_libraries`. Provides a structured, queryable classification system via `pg_seclabel`.
2. **Structured comments** (fallback) — embed classification metadata in table comments using a consistent format like `[classification: <value>]`. This works without any server configuration but is less structured.

Before applying security labels, verify a label provider is loaded:

```sql
SELECT * FROM pg_seclabel LIMIT 1;
```

If this returns an error about no provider, use the structured comment approach instead.

## Remediation: Apply security label to a table

```sql
SECURITY LABEL FOR {{ provider }} ON TABLE {{ schema }}.{{ asset }}
    IS '{{ label_value }}';
```

## Remediation: Apply security label to a column

```sql
SECURITY LABEL FOR {{ provider }} ON COLUMN {{ schema }}.{{ asset }}.{{ column }}
    IS '{{ label_value }}';
```

## Remediation: Add structured classification comment to a table

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS '[classification: {{ classification }}] {{ additional_description }}';
```

## Remediation: Add structured classification comment to a column

```sql
COMMENT ON COLUMN {{ schema }}.{{ asset }}.{{ column }} IS '[classification: {{ classification }}] {{ additional_description }}';
```
