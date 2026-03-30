#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") <action> <demo> [-c connection]

Provision or tear down demo environments for the AI-Ready Data skill.
Runs SQL against Snowflake via the Snowflake CLI (snow).

Actions:
  setup      Create demo schemas and load data
  teardown   Drop demo schemas

Demos:
  scan-agents   Estate scan → agents assessment (3 schemas)
  rag           RAG readiness assessment (1 schema)

Options:
  -c CONNECTION   Snowflake connection name (from ~/.snowflake/connections.toml)

Examples:
  $(basename "$0") setup scan-agents
  $(basename "$0") setup rag -c my_connection
  $(basename "$0") teardown scan-agents
EOF
    exit 1
}

[[ $# -lt 2 ]] && usage

ACTION="$1"
DEMO="$2"
shift 2

CONNECTION=""
while getopts "c:" opt; do
    case $opt in
        c) CONNECTION="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ "$ACTION" != "setup" && "$ACTION" != "teardown" ]]; then
    echo "Error: action must be 'setup' or 'teardown', got '$ACTION'"
    exit 1
fi

SQL_FILE="$SCRIPT_DIR/$DEMO/$ACTION.sql"

if [[ ! -f "$SQL_FILE" ]]; then
    echo "Error: $SQL_FILE not found"
    echo ""
    echo "Available demos:"
    for dir in "$SCRIPT_DIR"/*/; do
        dirname="$(basename "$dir")"
        [[ -f "$dir/setup.sql" ]] && echo "  $dirname"
    done
    exit 1
fi

echo "==> Running $ACTION for '$DEMO' demo..."
echo "    SQL: $SQL_FILE"
[[ -n "$CONNECTION" ]] && echo "    Connection: $CONNECTION"
echo ""

if [[ -n "$CONNECTION" ]]; then
    snow sql -f "$SQL_FILE" -c "$CONNECTION"
else
    snow sql -f "$SQL_FILE"
fi

echo ""
echo "==> $ACTION complete."
