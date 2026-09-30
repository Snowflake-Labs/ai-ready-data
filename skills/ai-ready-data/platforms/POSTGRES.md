# Postgres

Platform rules for SQL generation and execution. Requirement-specific context lives in each requirement's markdown files — this file covers only cross-cutting rules.

## SQL Rules

- Cast to float with `::FLOAT` or `::DOUBLE PRECISION`. Use `NULLIF()` for safe division denominators. There is no `COUNT_IF()` — use `COUNT(*) FILTER (WHERE ...)` instead.
- Catalog metadata lives in `information_schema` (portable) or `pg_catalog` (Postgres-specific, needed for things `information_schema` doesn't expose, like table sizes or index definitions).
- Identifiers are case-sensitive only when double-quoted at creation time. Unquoted identifiers are folded to lowercase — don't assume mixed-case names unless you know they were quoted.
- Random sampling uses `TABLESAMPLE SYSTEM (n)` (percentage, block-level, fast, approximate) or `TABLESAMPLE BERNOULLI (n)` (percentage, row-level, slower, more uniform). There is no row-count sampling like Snowflake's `TABLESAMPLE (n ROWS)`.
- `ALTER TABLE ... ALTER COLUMN ... SET DEFAULT` is supported and does not rewrite existing rows.
- `ALTER TABLE ... ALTER COLUMN ... SET NOT NULL` scans the table to verify no nulls exist; it will fail if any remain.
- Catalog views (`information_schema`, `pg_catalog`) reflect the current transaction snapshot — no replication lag to account for, unlike Snowflake's `account_usage`.

## Idempotency Guards

Before non-idempotent fix operations, run the guard query. Skip if the desired state already exists.

| Operation | Guard | Skip If |
|---|---|---|
| ALTER TABLE ADD CONSTRAINT | `SELECT 1 FROM information_schema.table_constraints WHERE table_name = '{asset}' AND constraint_name = '{name}'` | Has rows |
| ALTER COLUMN SET NOT NULL | `SELECT is_nullable FROM information_schema.columns WHERE table_name = '{asset}' AND column_name = '{column}'` | Already `NO` |
| CREATE INDEX | `SELECT 1 FROM pg_indexes WHERE tablename = '{asset}' AND indexname = '{name}'` | Has rows |
| CREATE POLICY (row-level security) | `SELECT 1 FROM pg_policies WHERE tablename = '{asset}' AND policyname = '{name}'` | Has rows |

## Permissions

When a check or fix fails with an access error, verify these grants:

| Access | Grant |
|---|---|
| `information_schema.*` / `pg_catalog.*` | `USAGE` on the target schema |
| Reading table data | `SELECT` on the target table(s) |
| `ALTER TABLE` fixes | Table ownership or `ALTER` privilege |
| Row-level security policies | Table ownership (only owners/superusers can create policies) |
