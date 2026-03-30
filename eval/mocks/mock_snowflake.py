"""High-level mock Snowflake environment builder.

Combines MockSQLTool with scenario-driven INFORMATION_SCHEMA responses
and requirement check results to simulate a complete Snowflake session.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from eval.mocks.mock_sql_tool import (
    MockColumn,
    MockDatabase,
    MockSchema,
    MockSQLResult,
    MockSQLTool,
    MockTable,
    SQLRoute,
    mock_information_schema_routes,
)


@dataclass
class RequirementScore:
    """Pre-configured score for a specific requirement check."""

    requirement: str
    value: float
    table: str | None = None
    column: str | None = None


@dataclass
class SnowflakeScenario:
    """Full mock Snowflake environment for a test.

    Combines database structure with expected requirement scores
    to produce a fully configured MockSQLTool.
    """

    name: str
    database: MockDatabase
    requirement_scores: list[RequirementScore] = field(default_factory=list)
    extra_routes: list[SQLRoute] = field(default_factory=list)

    def build_tool(self) -> MockSQLTool:
        tool = MockSQLTool()

        for route in mock_information_schema_routes(self.database):
            tool._routes.append(route)

        for score in self.requirement_scores:
            row: dict[str, Any] = {"value": score.value}
            if score.table:
                row["table_name"] = score.table
            if score.column:
                row["column_name"] = score.column

            tool.add_route(
                pattern=rf".*{score.requirement}.*|.*AS\s+value.*",
                result=MockSQLResult(
                    columns=list(row.keys()),
                    rows=[row],
                    value=score.value,
                ),
                requirement=score.requirement,
            )

        for route in self.extra_routes:
            tool._routes.append(route)

        return tool


# ---------------------------------------------------------------------------
# Convenience builders
# ---------------------------------------------------------------------------

def simple_schema(
    name: str = "PRODUCT_METRICS",
    table_names: list[str] | None = None,
    row_count: int = 10_000,
    columns_per_table: int = 8,
) -> MockSchema:
    """Build a simple mock schema with uniform tables."""
    names = table_names or ["USERS", "EVENTS", "PRODUCTS"]
    tables = []
    for tname in names:
        cols = [
            MockColumn(name=f"COL_{i}", data_type="VARCHAR")
            for i in range(columns_per_table)
        ]
        cols[0] = MockColumn(name="ID", data_type="NUMBER", nullable=False)
        tables.append(MockTable(name=tname, row_count=row_count, columns=cols))
    return MockSchema(name=name, tables=tables)


def simple_database(
    name: str = "ANALYTICS",
    schema_names: list[str] | None = None,
) -> MockDatabase:
    """Build a mock database with simple uniform schemas."""
    names = schema_names or ["PRODUCT_METRICS", "USER_BEHAVIOR", "RAW_EVENTS"]
    return MockDatabase(
        name=name,
        schemas=[simple_schema(name=s) for s in names],
    )
