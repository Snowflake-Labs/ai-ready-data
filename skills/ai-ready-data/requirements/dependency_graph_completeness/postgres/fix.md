# Fix: dependency_graph_completeness

Remediation guidance for objects without documented dependency relationships.

## Context

PostgreSQL's `pg_depend` catalog is automatically populated when views, materialized views, foreign keys, and other DDL-level references are created. There is no way to manually register a dependency. If objects show as having no dependencies, the cause is one of:

1. **Standalone base tables with no downstream views or consumers.** Common for raw/staging tables loaded by external ETL tools. Create a view or materialized view on top of these tables to establish a tracked dependency path.
2. **External tooling bypasses PostgreSQL dependency tracking.** If data is loaded via `COPY` or external orchestrators without creating views, PostgreSQL cannot infer dependencies. Document these relationships using comments.
3. **Missing foreign key constraints.** Adding foreign keys between related tables establishes dependency relationships tracked in `pg_depend`.

## Remediation: Create a view to establish a dependency

```sql
CREATE VIEW {{ schema }}.{{ asset }}_v AS
SELECT * FROM {{ schema }}.{{ asset }};
```

## Remediation: Add a foreign key to document a relationship

```sql
ALTER TABLE {{ schema }}.{{ child_table }}
    ADD CONSTRAINT fk_{{ child_table }}_{{ parent_table }}
    FOREIGN KEY ({{ foreign_key_column }})
    REFERENCES {{ schema }}.{{ parent_table }} ({{ referenced_column }});
```

## Remediation: Add a comment to document external dependencies

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'Upstream: <source_system> | Pipeline: <pipeline_name>';
```
