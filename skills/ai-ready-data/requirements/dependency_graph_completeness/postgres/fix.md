# Fix: dependency_graph_completeness

Remediation guidance for objects without documented dependency relationships.

## Context

PostgreSQL's `pg_depend` is automatically populated for views, materialized views, functions, and foreign key constraints. There is no DDL to manually register a dependency. If objects show as having no dependencies, the cause is typically:

1. **Standalone base tables with no downstream views or consumers.** Common for raw/staging tables. Create a view or materialized view to establish a tracked dependency.
2. **Missing foreign key constraints.** If tables have logical relationships but no FK constraints, adding them registers the dependency in `pg_depend`.
3. **External tooling bypasses PostgreSQL.** If data flows are managed by external orchestrators without creating SQL objects, the relationships won't appear in `pg_depend`. Document these with comments.

## Remediation: Create a view to establish a dependency

```sql
CREATE VIEW {{ schema }}.{{ view_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
```

## Remediation: Add a foreign key constraint

```sql
ALTER TABLE {{ schema }}.{{ child_table }}
ADD CONSTRAINT {{ constraint_name }}
FOREIGN KEY ({{ column }}) REFERENCES {{ schema }}.{{ parent_table }} ({{ parent_column }})
```

## Remediation: Add a comment to document external dependencies

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS
'Upstream: {{ source_system }} | Downstream: {{ consumer_systems }}'
```
