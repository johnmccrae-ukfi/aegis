"""Shared validation helpers for generated Aegis datasets."""

from collections.abc import Iterable, Mapping
from typing import Any


class GenerationValidationError(ValueError):
    """Raised when generated data fails a mandatory safety or quality check."""


def validate_expected_row_count(
    dataset_name: str,
    rows: list[Mapping[str, Any]],
    expected_count: int,
) -> None:
    """Confirm that a generated dataset contains the expected row count."""

    actual_count = len(rows)

    if actual_count != expected_count:
        raise GenerationValidationError(
            f"{dataset_name} expected {expected_count} rows "
            f"but generated {actual_count}."
        )


def validate_unique_values(
    dataset_name: str,
    rows: Iterable[Mapping[str, Any]],
    key_name: str,
) -> None:
    """Confirm that a selected field contains no duplicate values."""

    seen_values: set[Any] = set()
    duplicate_values: set[Any] = set()

    for row in rows:
        value = row[key_name]

        if value in seen_values:
            duplicate_values.add(value)

        seen_values.add(value)

    if duplicate_values:
        duplicate_text = ", ".join(
            str(value) for value in sorted(duplicate_values, key=str)
        )

        raise GenerationValidationError(
            f"{dataset_name}.{key_name} contains duplicate values: "
            f"{duplicate_text}"
        )


def validate_required_values(
    dataset_name: str,
    rows: Iterable[Mapping[str, Any]],
    required_keys: list[str],
) -> None:
    """Confirm that required generated fields are populated."""

    failures: list[str] = []

    for row_number, row in enumerate(rows, start=1):
        for key_name in required_keys:
            value = row.get(key_name)

            if value is None or value == "":
                failures.append(f"row {row_number}: {key_name}")

    if failures:
        failure_text = "; ".join(failures[:20])

        if len(failures) > 20:
            failure_text += f"; plus {len(failures) - 20} additional failures"

        raise GenerationValidationError(
            f"{dataset_name} contains missing required values: {failure_text}"
        )