# Fix: batch_throughput_sufficiency

Remediation guidance for improving batch load throughput and success rates.

## Context

Load failures and throughput issues in Snowflake are typically caused by file format mismatches, file sizing problems, or insufficient warehouse capacity. There is no single DDL fix — remediation depends on the root cause identified in the diagnostic.

## Fix: Investigate failed loads

Review the diagnostic output to identify patterns in failing loads. Common root causes:
- **File format errors:** Mismatched delimiters, encoding issues, or schema drift in source files. Fix the upstream file generation or update the `COPY INTO` file format options.
- **Empty loads:** Source files are empty or the file path pattern no longer matches. Verify the external stage and file naming conventions.
- **Partial loads:** `ON_ERROR = 'CONTINUE'` is masking row-level errors. Consider `ON_ERROR = 'ABORT_STATEMENT'` for stricter validation.

## Fix: Optimize file sizing

Snowflake recommends source files between 100-250 MB compressed for optimal parallel loading. Files that are too small create overhead; files that are too large prevent parallelism.

## Fix: Scale warehouse for load throughput

If loads succeed but are slow, consider a larger warehouse for the COPY INTO operation. Snowflake parallelizes file loading across warehouse nodes.
