# Fix: point_lookup_availability

Remediation guidance for enabling low-latency point lookups on tables.

## Context

Tables flagged as `NOT_OPTIMIZED` or partially optimized can be improved by adding a clustering key on frequently queried lookup columns and/or enabling search optimization. Clustering keys improve range scan and sort-merge performance, while search optimization accelerates equality and IN-list predicates. For best point-lookup performance, apply both.

`ALTER TABLE ... CLUSTER BY` silently replaces any existing clustering key. If the table already has a clustering key, the diagnostic output will reveal it — review before applying. `ADD SEARCH OPTIMIZATION` is idempotent and Enterprise-only.

## Fix: Add a clustering key

On the columns most commonly used in WHERE-clause filters:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} CLUSTER BY ({{ clustering_columns }});
```

## Fix: Enable search optimization

For fast equality and IN-list lookups:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} ADD SEARCH OPTIMIZATION;
```

## Verify

Confirm the changes took effect by re-running the diagnostic query or:

```sql
SHOW TABLES LIKE '{{ asset }}' IN SCHEMA {{ database }}.{{ schema }};
```
