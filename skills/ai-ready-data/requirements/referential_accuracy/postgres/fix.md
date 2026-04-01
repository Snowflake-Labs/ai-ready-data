# Fix: referential_accuracy

Remediation guidance for values that fail referential accuracy validation.

## Context

There is no single automated fix for referential accuracy failures — the correct action depends on why values don't match the reference table. Common remediation strategies:

1. **Correct typos or formatting mismatches** — If unverified values are near-matches (e.g., `"US "` vs `"US"`, `"usa"` vs `"USA"`), apply trimming or case normalization before re-checking.
2. **Expand the reference table** — If legitimate values are missing from the reference, add them to the reference/lookup table.
3. **Nullify or flag invalid values** — Replace values that are genuinely incorrect with NULL or a sentinel value, then re-assess completeness.
4. **Delete rows with invalid references** — If rows with unresolvable values are not useful downstream, remove them.

After applying fixes, re-run the check query to confirm the accuracy score has improved.
