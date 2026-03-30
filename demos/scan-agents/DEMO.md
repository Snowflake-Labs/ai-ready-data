# Estate Scan + Agents Assessment — Demo Guide

End-to-end walkthrough: provision a multi-schema environment, scan the data estate, identify the lowest-readiness schema, deep-assess it for agentic AI readiness, and remediate.

## Prerequisites

| Requirement | How to check |
|---|---|
| Snowflake account with `SNOWFLAKE_LEARNING_DB` access | `snow sql -q "SELECT CURRENT_ACCOUNT()"` |
| Snowflake CLI installed | `snow --version` |
| Connection configured in `~/.snowflake/connections.toml` | `snow sql -q "SELECT 1" -c <connection>` |
| Cortex Code CLI installed | `cortex --version` |
| Node.js / npx available | `npx --version` |
| Role with CREATE SCHEMA on `SNOWFLAKE_LEARNING_DB` | Ask your admin or use ACCOUNTADMIN for the demo |
| `IMPORTED PRIVILEGES` on the SNOWFLAKE database (for governance checks) | `snow sql -q "SHOW GRANTS ON DATABASE SNOWFLAKE"` |

If `SNOWFLAKE_LEARNING_DB` does not exist, create it first:

```sql
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_LEARNING_DB;
```

---

## Step 1: Install the Skill

Install into Cortex Code CLI from this repo:

```bash
# From a local clone
npx add-skill ./path/to/ai-ready-data-agent -a cortex

# Or from GitHub (once published)
npx add-skill your-org/ai-ready-data -a cortex
```

Verify:

```
cortex
/skill list
```

You should see `ai-ready-data` in the list.

---

## Step 2: Provision the Demo Environment

Run the setup script **outside of Cortex Code** — the point is that the agent discovers the data naturally, as it would in a real engagement.

```bash
./demos/run.sh setup scan-agents
# or, if using a specific connection:
./demos/run.sh setup scan-agents -c <your-connection>
```

The script creates multiple schemas in `SNOWFLAKE_LEARNING_DB` with intentionally different levels of data readiness — some well-governed, some partially, some raw. The final query prints a summary of what was created.

> **Do not read `setup.sql` during the demo.** The agent should encounter the data cold.

---

## Step 3: Scan the Data Estate

Start Cortex Code with your Snowflake connection:

```bash
cortex -c <your-connection> -w /path/to/ai-ready-data-agent
```

Then trigger the scan:

```
Scan my data estate for AI readiness
```

When the agent asks for the platform, choose **Snowflake**. When asked for the database, choose **SNOWFLAKE_LEARNING_DB**.

### What to expect

The agent runs the lightweight scan profile across all schemas in the database and presents a portfolio view — a comparative ranking of each schema by readiness score across four factors (Contextual, Consumable, Current, Compliant).

You should see a clear tier structure:

| Tier | Schema | Why |
|---|---|---|
| High | One analytics-focused schema | Fully documented, governed, optimized |
| Medium | One marketing-focused schema | Partially documented, limited governance |
| Low | One support-focused schema | No documentation, no governance, no optimization |

### Talking points

- **Portfolio view is the anchor.** It immediately shows which parts of the estate are AI-ready and which aren't, without running a deep assessment on everything.
- **Scan is fast.** It uses a lightweight profile (8 requirements across 4 factors) — designed for breadth, not depth.
- **Tier separation is real.** The difference between a well-governed schema and a raw one is stark even with lightweight checks.

---

## Step 4: Drill Into the Worst Schema

After the scan, the agent offers options. Pick the lowest-scoring schema for a deep assessment:

```
Assess that schema in depth
```

When asked for the assessment profile, choose **agents**:

```
Agents readiness
```

The agent will confirm scope and present a coverage summary. Approve to begin.

### What to expect

The agents profile is the broadest and most demanding — 36 requirements across all six factors with strict thresholds. The low-readiness schema should fail broadly:

| Stage (Factor) | Expected | Why |
|---|---|---|
| Clean | FAIL | Nulls, duplicates, encoding errors, bad types, invalid statuses, orphan FKs |
| Contextual | FAIL | No column comments, no primary keys, no constraints, no semantic views |
| Consumable | FAIL | No clustering, no search optimization on large table |
| Current | FAIL | No change tracking, no streams |
| Correlated | Partial | Query history may show some agent attribution |
| Compliant | FAIL | PII columns (email, phone) without masking, no tags, no row access policies |

### Talking points

- **Agents have the strictest requirements.** Autonomous agents amplify every data gap — a missing NULL in a human-queried table is an annoyance; in an agent-queried table it's a wrong answer delivered with confidence.
- **The thresholds explain why.** `data_completeness: 0.99` means the agents profile tolerates almost no missing values, vs. RAG at `0.98` or training at `0.95`.
- **The six factors map to real agent failure modes.** Dirty data → wrong answers. Missing context → failed Text-to-SQL. No optimization → slow tool calls. Stale data → confidently outdated answers. No governance → sensitive data leaks at scale.

---

## Step 5: Explore Diagnostics

Before jumping into remediation, drill into a specific failure:

```
Tell me more about data_completeness
```

The agent runs diagnostic SQL and shows which columns have nulls, how many, and in which tables. This demonstrates the two-phase workflow: understand the problem, then fix it.

Good requirements to drill into:

| Requirement | What the diagnostic shows |
|---|---|
| `data_completeness` | Which columns have nulls and how many |
| `uniqueness` | Which tables have duplicate key values |
| `encoding_validity` | Which columns contain encoding errors and what they look like |
| `semantic_documentation` | Which tables/columns are missing comments |

---

## Step 6: Remediate

Start the remediation loop:

```
Remediate the Clean stage
```

The agent will:

1. Show which requirements are failing
2. Load fix SQL for each one
3. Present a remediation plan with the exact SQL it will run
4. Wait for your approval before executing
5. Re-run the check SQL to show before/after scores

Good requirements to remediate live (the agent handles this automatically, but these make the best talking points):

| Requirement | What the fix does |
|---|---|
| `data_completeness` | Fill nulls with defaults or remove incomplete rows |
| `uniqueness` | Deduplicate tables using ROW_NUMBER |
| `encoding_validity` | Replace encoding errors (U+FFFD, null bytes) |
| `entity_identifier_declaration` | Add primary key constraints |
| `semantic_documentation` | Add column and table comments |
| `change_detection` | Enable change tracking on tables |
| `access_optimization` | Add clustering key to the large events table |

### Talking points

- **Remediation is agent-assisted, not agent-autonomous.** The agent proposes, you approve. Every fix shows the exact SQL before execution.
- **Before/after verification closes the loop.** After each fix, the check re-runs so you see the score improve in real time.
- **Some fixes are SQL, others are organizational.** Governance requirements (tags, masking policies, row access) often need human judgment about what to tag and how to mask — the agent provides guidance, not just code.

---

## Step 7: (Optional) Re-run the Scan

After remediating a few stages, go back to the estate level:

```
Scan the estate again
```

The previously-low schema should now score higher, showing the improvement in context. This closes the loop on the full workflow: scan → prioritize → assess → fix → verify.

> **Note:** Governance checks that use `snowflake.account_usage` views (tags, masking policies) have ~2 hour latency for newly created objects. If you create tags or policies during remediation, those checks may still show FAIL until the views catch up. Mention this as known Snowflake behavior.

---

## Step 8: Tear Down

```bash
./demos/run.sh teardown scan-agents
# or with a connection:
./demos/run.sh teardown scan-agents -c <your-connection>
```

This drops all demo schemas and everything in them. Safe to run multiple times.

---

## Tips for a Live Demo

- **Start with the scan.** The portfolio view is the hook — it answers "where should I focus?" before going deep.
- **Let the agent discover naturally.** Don't pre-explain the schemas. Let the scan results speak and then react.
- **Pick Clean for the first remediation.** It has the most tangible before/after (nulls disappear, duplicates removed, encoding fixed).
- **Show a diagnostic drill-down** before remediating to demonstrate the two-phase workflow.
- **Contrast with the high-readiness schema.** After showing the low-readiness gaps, briefly mention that the well-governed schema passed those same checks — the difference is investment in data governance.
- **Time budget:** Scan takes 2-3 minutes. Full agents assessment takes 5-10 minutes. Remediating one stage takes 3-5 minutes. Plan for a 20-30 minute demo to cover scan → assess → diagnostics → one-stage remediation.

---

## File Reference

| File | Purpose |
|---|---|
| `demos/scan-agents/setup.sql` | Creates 3 schemas with different readiness levels |
| `demos/scan-agents/teardown.sql` | Drops all scan demo schemas |
| `demos/scan-agents/DEMO.md` | This guide |
| `demos/run.sh` | Provisions and tears down demo environments |
