# Fix: temporal_referential_integrity

Remediation guidance for records with invalid or missing event timestamps.

## Context

This requirement has no automated SQL fix because the correct remediation depends on the root cause:

1. **NULL timestamps** — Backfill from a source system audit column, ingestion metadata, or set a default value at the column level.
2. **Future timestamps** — Typically a data-entry or timezone-conversion error. Correct at the source or clamp to `CURRENT_TIMESTAMP`.
3. **Ancient timestamps (before 1900)** — Usually a placeholder or default value. Replace with the actual origination time or NULL and handle downstream.
4. **Epoch timestamps (1970-01-01)** — Often an uninitialized Unix timestamp. Investigate the source pipeline and replace with the real event time.

No single fix applies universally. Use the diagnostic query to understand the breakdown, then apply targeted updates.
