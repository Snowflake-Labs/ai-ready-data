# Fix: semantic_documentation

Remediation strategies for tables lacking machine-readable semantic descriptions.

## Context

There are two remediation paths with very different outcomes:

- **Semantic View (recommended)** — Creates a machine-readable model of your tables, relationships, metrics, and dimensions. Powers Text-to-SQL, Cortex Analyst, and agentic queries. This is the strongest fix and should be the default recommendation. Follow the [Semantic View Builder](./semantic-view-builder.md) workflow for guided creation.
- **Column/Table Comments (lightweight fallback)** — Adds human-readable descriptions to tables and columns. Improves documentation score but does not enable structured query generation. Only use when the user explicitly opts for comments over semantic views.

### Remediation: create-semantic-view

Create a semantic view covering the target tables. This is the preferred path — see [semantic-view-builder.md](./semantic-view-builder.md) for the full guided workflow including schema discovery, table role assignment, relationship mapping, metric definition, and deployment verification.

```sql
CREATE OR REPLACE SEMANTIC VIEW {{ database }}.{{ schema }}.{{ semantic_view_name }}

    TABLES (
        {{ table_definitions }}
    )

    RELATIONSHIPS (
        {{ relationship_definitions }}
    )

    FACTS (
        {{ fact_definitions }}
    )

    DIMENSIONS (
        {{ dimension_definitions }}
    )

    METRICS (
        {{ metric_definitions }}
    )

    COMMENT = '{{ comment }}'
```

### Remediation: add-comments

Add comments to tables and columns. This is a fallback for users who cannot or choose not to create semantic views. Comments improve human readability and basic tooling support but do not enable Text-to-SQL or Cortex Analyst.

```sql
COMMENT ON TABLE {{ database }}.{{ schema }}.{{ asset }} IS '{{ table_comment }}';
COMMENT ON COLUMN {{ database }}.{{ schema }}.{{ asset }}.{{ column }} IS '{{ column_comment }}'
```
