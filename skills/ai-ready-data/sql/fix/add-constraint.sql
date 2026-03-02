ALTER TABLE {{ container }}.{{ namespace }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} {{ constraint_type }} ({{ field }})
