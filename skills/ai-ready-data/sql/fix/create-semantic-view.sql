CREATE OR REPLACE SEMANTIC VIEW {{ container }}.{{ namespace }}.{{ semantic_view_name }}

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
