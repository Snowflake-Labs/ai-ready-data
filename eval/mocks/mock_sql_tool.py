"""Mock SQL execution tool for deterministic testing.

Returns pre-configured result sets based on scenario definitions.
Captures all SQL for trajectory analysis without touching a real database.
"""

from __future__ import annotations

import re
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any


@dataclass
class MockSQLResult:
    """A canned result for a SQL pattern match."""

    columns: list[str]
    rows: list[dict[str, Any]]
    value: float | None = None  # shorthand for check results
    error: str | None = None

    def as_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {"columns": self.columns, "rows": self.rows}
        if self.value is not None:
            result["value"] = self.value
        return result


@dataclass
class SQLRoute:
    """Maps a SQL pattern to a canned result."""

    pattern: str  # regex matched against the SQL
    result: MockSQLResult
    requirement: str | None = None
    call_count: int = 0

    def matches(self, sql: str) -> bool:
        return bool(re.search(self.pattern, sql, re.IGNORECASE | re.DOTALL))


class MockSQLTool:
    """Deterministic SQL executor that returns scenario-configured results.

    Usage:
        tool = MockSQLTool()
        tool.add_route(
            pattern=r"SELECT.*data_completeness.*FROM",
            result=MockSQLResult(
                columns=["table_name", "column_name", "value"],
                rows=[{"table_name": "USERS", "column_name": "EMAIL", "value": 0.95}],
                value=0.95,
            ),
            requirement="data_completeness",
        )
        result = tool.execute("SELECT ... FROM ANALYTICS.PRODUCT_METRICS.USERS")
    """

    def __init__(self) -> None:
        self._routes: list[SQLRoute] = []
        self._fallback: MockSQLResult = MockSQLResult(
            columns=["value"],
            rows=[{"value": 1.0}],
            value=1.0,
        )
        self.call_log: list[tuple[str, MockSQLResult]] = []

    def add_route(
        self,
        pattern: str,
        result: MockSQLResult,
        requirement: str | None = None,
    ) -> None:
        self._routes.append(SQLRoute(pattern=pattern, result=result, requirement=requirement))

    def set_fallback(self, result: MockSQLResult) -> None:
        self._fallback = result

    def execute(self, sql: str) -> dict[str, Any]:
        for route in self._routes:
            if route.matches(sql):
                route.call_count += 1
                self.call_log.append((sql, route.result))
                if route.result.error:
                    raise RuntimeError(route.result.error)
                return route.result.as_dict()

        self.call_log.append((sql, self._fallback))
        return self._fallback.as_dict()

    def reset(self) -> None:
        for route in self._routes:
            route.call_count = 0
        self.call_log.clear()

    @property
    def total_calls(self) -> int:
        return len(self.call_log)

    def calls_for_requirement(self, requirement: str) -> list[tuple[str, MockSQLResult]]:
        return [
            (sql, result)
            for sql, result in self.call_log
            for route in self._routes
            if route.requirement == requirement and route.matches(sql)
        ]


# ---------------------------------------------------------------------------
# Information schema mocks for discovery phase
# ---------------------------------------------------------------------------

@dataclass
class MockDatabase:
    name: str
    schemas: list[MockSchema] = field(default_factory=list)


@dataclass
class MockSchema:
    name: str
    tables: list[MockTable] = field(default_factory=list)


@dataclass
class MockTable:
    name: str
    row_count: int = 1000
    columns: list[MockColumn] = field(default_factory=list)
    has_clustering_key: bool = False
    has_change_tracking: bool = False
    has_tags: bool = False
    comment: str | None = None


@dataclass
class MockColumn:
    name: str
    data_type: str = "VARCHAR"
    nullable: bool = True
    comment: str | None = None
    has_masking_policy: bool = False


def mock_information_schema_routes(db: MockDatabase) -> list[SQLRoute]:
    """Generate SQL routes that simulate INFORMATION_SCHEMA queries."""
    routes: list[SQLRoute] = []

    # SHOW DATABASES / list schemas
    schema_rows = []
    for schema in db.schemas:
        schema_rows.append({
            "SCHEMA_NAME": schema.name,
            "TABLE_COUNT": len(schema.tables),
        })

    routes.append(SQLRoute(
        pattern=r"(?:SHOW\s+SCHEMAS|INFORMATION_SCHEMA\.SCHEMATA)",
        result=MockSQLResult(
            columns=["SCHEMA_NAME", "TABLE_COUNT"],
            rows=schema_rows,
        ),
    ))

    # Per-schema table listing
    for schema in db.schemas:
        table_rows = [
            {
                "TABLE_NAME": t.name,
                "ROW_COUNT": t.row_count,
                "COLUMN_COUNT": len(t.columns),
                "COMMENT": t.comment or "",
            }
            for t in schema.tables
        ]
        routes.append(SQLRoute(
            pattern=rf"(?:SHOW\s+TABLES|INFORMATION_SCHEMA\.TABLES).*{schema.name}",
            result=MockSQLResult(
                columns=["TABLE_NAME", "ROW_COUNT", "COLUMN_COUNT", "COMMENT"],
                rows=table_rows,
            ),
        ))

    return routes
