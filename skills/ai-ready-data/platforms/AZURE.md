# Azure

Azure platform support targets Fabric, Synapse, and Purview. No requirement implementations exist yet.

## Capabilities

- Row-level security via Synapse/Fabric
- Lineage via Microsoft Purview
- Governance tags via Purview classifications and sensitivity labels
- SQL-based check execution via Synapse/Fabric SQL endpoints

## Not Supported

- Semantic views
- Native column masking (dynamic data masking exists in Synapse but different model)
- Vector index introspection
- Change tracking introspection
- SQL-based fix execution (most governance changes require Purview API or portal)

## SQL Dialect

- Synapse uses T-SQL dialect.
- Use `CAST(x AS FLOAT)` for casting.
- No `COUNT_IF` — use `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`.
- `NULLIF()` works the same.
- `information_schema` access depends on the Synapse/Fabric workspace configuration.

## Required Permissions

- Synapse/Fabric SQL endpoint access
- Purview reader role for governance and lineage
- Appropriate workspace role for metadata visibility
