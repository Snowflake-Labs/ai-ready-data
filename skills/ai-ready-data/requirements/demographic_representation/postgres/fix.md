# Fix: demographic_representation

Remediation steps to document demographic columns so representation can be measured.

## Context

Two-step process: first add a comment to the table documenting its demographic context, then add comments to specific columns that contain demographic or protected-class data. PostgreSQL comments take effect immediately — no propagation delay like Snowflake's tag system.

Demographic attributes are sensitive — handle with appropriate access controls.

### Add table-level demographic documentation

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'demographic: contains protected class data; {{ additional_context }}';
```

### Add column-level demographic documentation

Sets a comment on a specific column. Repeat for each column that contains demographic or protected-class data.

```sql
COMMENT ON COLUMN {{ schema }}.{{ asset }}.{{ column }} IS 'sensitive_attribute: {{ attribute_type }}; {{ additional_context }}';
```
