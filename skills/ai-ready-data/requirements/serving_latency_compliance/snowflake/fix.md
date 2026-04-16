# Fix: serving_latency_compliance

Remediation guidance for queries exceeding the latency SLA.

## Context

There is no single DDL fix for latency compliance — optimization depends on the specific queries and tables involved. Common remediation strategies:

1. **Add clustering keys.** Tables frequently filtered or joined on specific columns benefit from clustering, which reduces scan volume and improves query latency.
2. **Right-size the warehouse.** Queries running on undersized warehouses may queue or spill to disk. Scale up the warehouse or use a dedicated warehouse for latency-sensitive serving queries.
3. **Materialize expensive subqueries.** If the diagnostic shows repeated slow patterns (e.g., large joins or aggregations), consider pre-computing results into a dynamic table or materialized view.
4. **Reduce bytes scanned.** Select only the columns needed, apply filters early, and avoid `SELECT *` on wide tables.
5. **Review query design.** Anti-patterns like correlated subqueries, excessive `FLATTEN` on large arrays, or missing predicates inflate elapsed time.

## Fix: Add clustering key

`ALTER TABLE ... CLUSTER BY` silently replaces any existing clustering key. Inspect the current key via `SHOW TABLES LIKE '{{ asset }}'` before applying.

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} CLUSTER BY ({{ clustering_columns }});
```

## Fix: Resize warehouse

```sql
ALTER WAREHOUSE {{ warehouse }} SET WAREHOUSE_SIZE = '{{ warehouse_size }}';
```
