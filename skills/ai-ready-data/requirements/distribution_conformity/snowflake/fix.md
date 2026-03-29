# Fix: distribution_conformity

Remediation guidance for distribution drift.

## Context

Distribution drift cannot be corrected with a single SQL statement — it reflects a change in the underlying data-generating process. Remediation depends on the root cause and the severity of drift.

**If drift is caused by upstream data quality issues:**
- Investigate recent changes to source systems or ETL pipelines that feed the column.
- Check for schema changes, unit conversions, or broken transformations.
- Correct the upstream issue and backfill affected rows if necessary.

**If drift reflects a legitimate change in the population:**
- Update the declared baseline (`baseline_mean`, `baseline_stddev`) to match the new distribution.
- Re-run the check to confirm the updated baseline produces an acceptable conformity score.
- Document the baseline change and the reason for it.

**If drift is caused by outliers or bad records:**
- Use the diagnostic query to inspect the statistical profile (min, max, IQR, p95).
- Identify and remove or cap outlier rows that skew the distribution.
- Consider adding data validation rules upstream to prevent future outlier ingestion.