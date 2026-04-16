# Fix: access_optimization

Add clustering keys to large tables that lack them.

## Context

Clustering keys tell Snowflake how to physically organize data within micro-partitions, dramatically improving query performance for filtered scans and joins on the clustered columns. This is the single most impactful optimization for tables frequently queried by AI workloads.

Choose clustering columns based on the most common filter and join predicates. Good candidates are:
- Foreign key columns used in joins
- Date/timestamp columns used in range filters
- Low-to-medium cardinality columns used in WHERE clauses

Avoid clustering on high-cardinality columns (e.g., unique IDs) unless they're used for point lookups. Snowflake recommends 1-3 clustering columns.

Adding a clustering key does not rewrite existing data immediately — Snowflake's automatic clustering service reorganizes data in the background over time. There is an ongoing compute cost for automatic reclustering.

**`ALTER TABLE ... CLUSTER BY` silently replaces any existing clustering key.** Before applying, inspect the current key — if one is already set to a different expression, confirm with the owner that replacing it is intended.

```sql
SELECT clustering_key
FROM {{ database }}.information_schema.tables
WHERE table_schema = '{{ schema }}' AND table_name = '{{ asset }}';
```

If the query returns a non-null value and it equals `LINEAR({{ clustering_columns }})`, the fix is a no-op — skip it. If it returns a different expression, warn the user and get explicit approval before proceeding.

## Fix: Add a clustering key

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
CLUSTER BY ({{ clustering_columns }})
```
