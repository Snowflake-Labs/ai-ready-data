# Fix: dependency_graph_completeness

Remediation guidance for objects without documented dependency relationships.

## Context

Snowflake's `object_dependencies` view is automatically populated for views, dynamic tables, streams, tasks, and other objects that reference other objects via SQL. There is no DDL to manually register a dependency. If objects show as having no dependencies, the cause is one of:

1. **Standalone base tables with no downstream views or consumers.** This is common for raw/staging tables loaded by external ETL tools. Consider creating a view or dynamic table on top of these tables to establish a tracked lineage path.
2. **External tooling bypasses Snowflake lineage.** If data is loaded via COPY INTO or external orchestrators, Snowflake cannot infer upstream dependencies. Document these relationships using comments or tags.
3. **Missing IMPORTED PRIVILEGES.** The role running the assessment needs `IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE` to read `account_usage.object_dependencies`. Grant this to the assessment role.
4. **Latency.** Recently created objects or newly established references may not appear for ~2 hours. Re-run the check after the latency window.

## Remediation: Grant access to dependency views

```sql
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE {{ role }};
```

## Remediation: Add a comment to document external dependencies

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} SET COMMENT = 'Upstream: <source_system> | Pipeline: <pipeline_name>';
```
