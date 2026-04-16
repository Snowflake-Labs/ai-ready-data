# Fix: incremental_update_coverage

No single automated fix. Moving a table onto an incremental-update path is a pipeline-design decision.

## Remediation Guidance

The check counts dynamic tables as incremental-capable. Two paths improve the score, chosen per table:

1. **Wrap the table as a dynamic table** — rewrite the transformation that produces the table as a `CREATE DYNAMIC TABLE ... TARGET_LAG ... WAREHOUSE ... AS SELECT ...`. Snowflake handles incremental maintenance automatically. See `training_serving_parity/snowflake/fix.md` for the DDL pattern.
2. **Enable change tracking + create a stream** — preserves the existing base table while exposing CDC events for downstream consumers. See `change_detection/snowflake/fix.md` for the two-step workflow (`ALTER TABLE ... SET CHANGE_TRACKING = TRUE`, then `CREATE STREAM`).

Choose (1) when the upstream SQL can be declared once and Snowflake should own refreshes. Choose (2) when multiple downstream consumers need to react to changes and you want to keep the base table mutable.
