# Fix: eval_coverage

No automated SQL fix — adding an evaluation dataset is a design decision that belongs with the team that owns the base data.

## Context

The check looks for companion tables whose name matches `(^eval_|_eval$|_eval_)`. Creating one means standing up a small, curated dataset that exercises the ways downstream AI tools will read the base table: representative rows, known-good outputs, known edge cases, and intentionally malformed rows for negative coverage.

## Remediation Guidance

1. **Decide the scope.** An eval table typically has 100–10,000 rows — large enough to cover edge cases, small enough to inspect manually when an agent regresses.
2. **Create the eval table** using one of the naming conventions the check recognizes: `{{ asset }}_eval`, `eval_{{ asset }}`, or an equivalent variant. Mirror the base table's columns, plus:
   - `eval_id` (stable identifier for each test case)
   - `expected_result` or `expected_output` (what a correct AI response looks like)
   - `notes` (what this case is testing — edge, null handling, adversarial, etc.)
3. **Populate from golden data.** Extract a deliberate sample rather than a random one — include every status value, both tails of each numeric range, null-bearing rows, and known-tricky records flagged by diagnostics.
4. **Keep it version-controlled.** Either seed the eval table from a SQL file checked into the team's repo, or store it as a dynamic table sourced from a curated view so the definition is code-reviewable.
5. **Wire it into CI or a scheduled check.** The mere presence of the table makes the requirement pass, but the value is realized only when AI tool changes are validated against it before rolling out.
