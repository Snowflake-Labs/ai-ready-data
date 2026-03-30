# Demos

Pre-built demo environments for the AI-Ready Data skill. Each demo provisions Snowflake schemas with intentional data quality and governance gaps, then guides you through the skill's assessment and remediation workflow.

## Available Demos

| Demo | Directory | What it shows |
|---|---|---|
| **Scan + Agents** | `scan-agents/` | Estate-level scan across 3 schemas → drill into the worst → full agents assessment → remediate |
| **RAG Readiness** | `rag/` | Single-schema RAG readiness assessment → diagnostics → remediate |

## Quick Start

```bash
# Provision a demo environment
./demos/run.sh setup <demo-name>

# Tear it down when done
./demos/run.sh teardown <demo-name>

# Use a specific Snowflake connection
./demos/run.sh setup scan-agents -c my_connection
```

Then open the `DEMO.md` in the demo directory for the full walkthrough.

## Which Demo Should I Run?

- **First time?** Start with **Scan + Agents**. It covers the full workflow from estate-level discovery through deep assessment and remediation, and demonstrates the most capabilities in a single session.

- **Focused on RAG?** Run the **RAG Readiness** demo. It goes straight into a single-schema assessment with the RAG profile — good for audiences specifically interested in retrieval-augmented generation pipelines.

- **Have 20 minutes?** Either demo works. Scan + Agents is broader; RAG is more focused.

- **Have 10 minutes?** Run Scan + Agents but stop after the scan and first assessment — skip remediation.

## Prerequisites

All demos require:

- Snowflake account with access to `SNOWFLAKE_LEARNING_DB`
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index) (`snow`) installed and configured
- [Cortex Code CLI](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-code) installed
- Node.js / npx (for skill installation)
- A role with CREATE SCHEMA privileges (ACCOUNTADMIN works for demos)
- `IMPORTED PRIVILEGES` on the SNOWFLAKE database (for governance checks)

See each demo's `DEMO.md` for detailed prerequisites and setup instructions.
