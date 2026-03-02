CREATE TAG IF NOT EXISTS {{ container }}.{{ namespace }}.{{ tag_name }}
    ALLOWED_VALUES {{ allowed_values }}
    COMMENT = '{{ comment }}'
