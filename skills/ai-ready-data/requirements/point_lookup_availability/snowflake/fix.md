# Fix: point_lookup_availability

Remediation guidance for enabling low-latency point lookups on tables.

## Context

Tables flagged as `NOT_OPTIMIZED` or partially optimized can be improved by adding a clustering key on frequently queried lookup columns and/or enabling search optimization. Clustering keys improve range scan and sort-merge performance, while search optimization accelerates equality and IN-list predicates. For best point-lookup performance, apply both.

**Add a clustering key** on the columns most commonly used in WHERE-clause filters:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} CLUSTER BY ({{ column }});
```

**Enable search optimization** for fast equality lookups:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} ADD SEARCH OPTIMIZATION;
```

**Verify** the changes took effect by re-running the diagnostic query or:

```sql
SHOW TABLES LIKE '{{ table }}' IN SCHEMA {{ database }}.{{ schema }};
```
