ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
SET TAG {{ tag1_name }} = '{{ tag1_value }}',
        {{ tag2_name }} = '{{ tag2_value }}'
