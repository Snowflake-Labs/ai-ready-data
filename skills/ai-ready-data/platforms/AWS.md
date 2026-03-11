# AWS

AWS platform support targets Athena, Glue, and Lake Formation. No requirement implementations exist yet.

## Capabilities

- Lineage via AWS Glue Data Catalog lineage
- Governance tags via Lake Formation tags
- SQL-based check execution via Athena

## Not Supported

- Semantic views
- Native column masking (Lake Formation has column-level security but not masking policies)
- Row access policies (Lake Formation has cell-level security but different model)
- Vector index introspection
- Change tracking introspection
- SQL-based fix execution (most governance changes require API calls, not SQL)

## SQL Dialect

- Athena uses Trino/Presto SQL dialect.
- No `::FLOAT` casting — use `CAST(x AS DOUBLE)`.
- No `COUNT_IF` — use `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`.
- `information_schema` access depends on Glue Data Catalog configuration.

## Required Permissions

- Athena query execution permissions
- Glue Data Catalog read access
- Lake Formation tag read permissions (for governance checks)
