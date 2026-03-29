# Fix: search_optimization

Remediation for tables without search optimization.

## Context

Search optimization is a table-level property that accelerates selective point-lookup and substring queries by maintaining a persistent search access path. It is most effective on tables >1GB; enabling it on smaller tables adds storage cost with minimal query benefit.

Enabling search optimization does not lock the table or block DML. Snowflake builds the access path asynchronously in the background. There may be a brief period after enablement during which queries are not yet accelerated.

## Remediation: Enable search optimization

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} ADD SEARCH OPTIMIZATION
```
