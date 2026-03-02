DELETE FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} < {{ min_value }} OR {{ field }} > {{ max_value }}
