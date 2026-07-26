"""File-output utilities for the Aegis synthetic-data generator."""

import csv
import json
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any


def ensure_directory(directory: Path) -> None:
    """Create an output directory and any missing parents."""

    directory.mkdir(parents=True, exist_ok=True)


def write_csv(
    output_path: Path,
    rows: Iterable[Mapping[str, Any]],
    fieldnames: list[str],
) -> int:
    """
    Write dictionaries to a UTF-8 CSV file.

    Returns the number of rows written.
    """

    ensure_directory(output_path.parent)

    row_count = 0

    with output_path.open(
        mode="w",
        encoding="utf-8",
        newline="",
    ) as output_file:
        writer = csv.DictWriter(
            output_file,
            fieldnames=fieldnames,
            extrasaction="raise",
        )

        writer.writeheader()

        for row in rows:
            writer.writerow(row)
            row_count += 1

    return row_count


def write_json(
    output_path: Path,
    payload: Mapping[str, Any] | list[Any],
) -> None:
    """Write a JSON document using UTF-8 encoding."""

    ensure_directory(output_path.parent)

    with output_path.open(
        mode="w",
        encoding="utf-8",
    ) as output_file:
        json.dump(
            payload,
            output_file,
            indent=2,
            ensure_ascii=False,
            default=str,
        )

        output_file.write("\n")