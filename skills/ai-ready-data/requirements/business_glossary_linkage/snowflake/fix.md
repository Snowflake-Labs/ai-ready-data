# Fix: business_glossary_linkage

Add glossary linkage to undocumented columns via comments or tags.

## Context

Two approaches, in order of preference:
1. **Tags** — create a glossary tag and apply it to columns with their business term. This is the structured approach and enables programmatic discovery.
2. **Comments** — add meaningful column comments (>20 characters) that define the business term. This is simpler but less structured.

For schemas with many undocumented columns, consider using the `semantic_documentation` requirement's semantic view builder workflow, which creates comprehensive machine-readable metadata in a single pass.

## Remediation: Add column comments

```sql
COMMENT ON COLUMN {{ database }}.{{ schema }}.{{ asset }}.{{ column }} IS '{{ comment }}';
```

## Remediation: Create a glossary tag and apply it

```sql
CREATE TAG IF NOT EXISTS {{ database }}.{{ schema }}.business_term
    COMMENT = 'Business glossary term definition';
```

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ALTER COLUMN {{ column }} SET TAG business_term = '{{ tag_value }}';
```
