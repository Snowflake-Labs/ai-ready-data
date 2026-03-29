# Fix: relationship_declaration

Creates a semantic view with relationship declarations.

## Context

Relationships define join paths — ensure they match actual foreign keys.

## SQL

### fix.create-semantic-view

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