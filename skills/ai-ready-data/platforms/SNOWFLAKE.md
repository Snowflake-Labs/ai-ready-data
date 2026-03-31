# Snowflake

Platform rules for SQL generation and execution. Requirement-specific context lives in each requirement's markdown files — this file covers only cross-cutting rules.

## SQL Rules

- Cast to float with `::FLOAT`. Use `COUNT_IF()` for conditional counts. Use `NULLIF()` for safe division denominators.
- `SHOW` commands return **lowercase quoted** column names. Always double-quote identifiers in `RESULT_SCAN`:
  ```sql
  SELECT "change_tracking" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
  ```
- `SHOW` and `RESULT_SCAN` must execute in the **same session**. Do not split them across separate SQL calls.
- `snowflake.account_usage` views have **~2 hour latency**. Warn the user when recently created objects are missing.
- `ALTER TABLE ... ALTER COLUMN ... SET DEFAULT` is not supported. Defaults must be set at table creation.

## Idempotency Guards

Before non-idempotent fix operations, run the guard query. Skip if the desired state already exists.

| Operation | Guard | Skip If |
|---|---|---|
| CREATE TAG | `SHOW TAGS LIKE '{name}' IN SCHEMA {schema}` | Has rows |
| CREATE MASKING POLICY | `SHOW MASKING POLICIES LIKE '{name}' IN SCHEMA {schema}` | Has rows |
| CREATE STREAM | `SHOW STREAMS LIKE '{name}' IN SCHEMA {schema}` | Has rows |
| ALTER COLUMN SET NOT NULL | `DESCRIBE TABLE {asset}` | Column already NOT NULL |
| CREATE SEMANTIC VIEW | No guard needed | `CREATE OR REPLACE` is safe |

## Delegations

| Requirement | Delegate To | When |
|---|---|---|
| `semantic_documentation` | Semantic View Builder (`requirements/semantic_documentation/snowflake/semantic-view-builder.md`) | Tables lack semantic views |
| `column_masking` | `data-policy` skill | Before creating masking policies |
| `classification` | `sensitive-data-classification` skill | Before creating tags via SYSTEM$CLASSIFY |

## Permissions

When a check or fix fails with an access error, verify these grants:

| Access | Grant |
|---|---|
| `information_schema.*` | USAGE on the target schema |
| `snowflake.account_usage.*` | `GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE {role}` |
| `SNOWFLAKE.CORTEX.*` | `GRANT USAGE ON SCHEMA SNOWFLAKE.CORTEX TO ROLE {role}` |
| `SNOWFLAKE.CORE.*` (DMFs) | `GRANT USAGE ON SCHEMA SNOWFLAKE.CORE TO ROLE {role}` |
