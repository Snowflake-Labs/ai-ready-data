# Fix: record_level_traceability

## Remediation Guidance

No automated fix SQL is provided for this requirement. Adding a trace identifier column requires understanding each table's data pipeline and choosing the appropriate identifier type.

**Recommended steps:**

1. **Identify the source system's native identifier.** If the upstream system already emits a correlation or trace ID, propagate it into Snowflake rather than generating a new one.

2. **Add a trace column to tables that lack one.** Use a standard name from the recognized set (`correlation_id`, `trace_id`, `request_id`, `event_id`, `source_id`, `origin_id`, `record_id`, `lineage_id`):

   ```sql
   ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} ADD COLUMN trace_id VARCHAR;
   ```

3. **Backfill existing rows** with a UUID or the originating system's identifier:

   ```sql
   UPDATE {{ database }}.{{ schema }}.{{ asset }}
   SET trace_id = UUID_STRING()
   WHERE trace_id IS NULL;
   ```
4. **Update ingestion pipelines** to populate the trace column on every new record so the backfill is not needed going forward.
