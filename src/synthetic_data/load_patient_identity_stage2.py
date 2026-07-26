"""Load Stage 2 Aegis patient-identity records into Aegis_Source."""

from __future__ import annotations

import argparse
import csv
import os
from datetime import date, datetime
from pathlib import Path
from typing import Any

import pyodbc

from synthetic_data.config import GeneratorConfig


BASELINE_IDENTIFIER_COUNT = 2_000
EXPECTED_ADDITIONAL_IDENTIFIER_COUNT = 170
EXPECTED_FINAL_IDENTIFIER_COUNT = 2_170


COLUMNS = (
    "PatientIdentifierId",
    "PatientId",
    "IdentifierValue",
    "IdentifierTypeCode",
    "AssigningAuthority",
    "EffectiveFromDate",
    "EffectiveToDate",
    "IsCurrent",
    "CreatedAtUtc",
    "UpdatedAtUtc",
)


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Validate or load Stage 2 patient identifiers into "
            "the Aegis_Source database."
        )
    )

    parser.add_argument(
        "--load",
        action="store_true",
        help="Load Stage 2 rows. Without this flag, validation only.",
    )

    return parser.parse_args()


def build_connection_string() -> str:
    """Build the SQL Server connection string."""

    driver = os.getenv(
        "AEGIS_SQL_DRIVER",
        "ODBC Driver 18 for SQL Server",
    )
    server = os.getenv(
        "AEGIS_SQL_SERVER",
        "DESKTOP-N58JDOH",
    )
    database = os.getenv(
        "AEGIS_SQL_DATABASE",
        "Aegis_Source",
    )

    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )


def convert_value(
    raw_value: str | None,
    column_name: str,
) -> Any:
    """Convert one CSV value into a strongly typed parameter."""

    if raw_value is None or raw_value == "":
        return None

    if column_name in {
        "PatientIdentifierId",
        "PatientId",
    }:
        return int(raw_value)

    if column_name == "IsCurrent":
        return bool(int(raw_value))

    if column_name in {
        "EffectiveFromDate",
        "EffectiveToDate",
    }:
        return date.fromisoformat(raw_value)

    if column_name in {
        "CreatedAtUtc",
        "UpdatedAtUtc",
    }:
        return datetime.fromisoformat(raw_value)

    return raw_value


def read_stage2_rows(
    input_path: Path,
) -> list[dict[str, Any]]:
    """Read the combined file and return only rows added in Stage 2."""

    if not input_path.exists():
        raise FileNotFoundError(
            f"Required generated file does not exist: {input_path}"
        )

    with input_path.open(
        mode="r",
        encoding="utf-8",
        newline="",
    ) as input_file:
        reader = csv.DictReader(input_file)

        actual_columns = tuple(reader.fieldnames or ())

        if actual_columns != COLUMNS:
            raise ValueError(
                "patient_identifier_stage2.csv columns do not match "
                "the expected schema."
            )

        all_rows = [
            {
                column_name: convert_value(
                    raw_value=raw_row[column_name],
                    column_name=column_name,
                )
                for column_name in COLUMNS
            }
            for raw_row in reader
        ]

    if len(all_rows) != EXPECTED_FINAL_IDENTIFIER_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_FINAL_IDENTIFIER_COUNT} combined rows "
            f"but found {len(all_rows)}."
        )

    additional_rows = [
        row
        for row in all_rows
        if int(row["PatientIdentifierId"]) > BASELINE_IDENTIFIER_COUNT
    ]

    if len(additional_rows) != EXPECTED_ADDITIONAL_IDENTIFIER_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_ADDITIONAL_IDENTIFIER_COUNT} Stage 2 rows "
            f"but found {len(additional_rows)}."
        )

    return additional_rows


def validate_stage2_rows(
    rows: list[dict[str, Any]],
) -> None:
    """Validate the additional historic and duplicate identifier rows."""

    identifier_ids = [
        int(row["PatientIdentifierId"])
        for row in rows
    ]

    if len(identifier_ids) != len(set(identifier_ids)):
        raise ValueError(
            "Stage 2 PatientIdentifierId values are not unique."
        )

    expected_ids = set(
        range(
            BASELINE_IDENTIFIER_COUNT + 1,
            EXPECTED_FINAL_IDENTIFIER_COUNT + 1,
        )
    )

    if set(identifier_ids) != expected_ids:
        raise ValueError(
            "Stage 2 identifier IDs are not the expected continuous "
            "range 2001–2170."
        )

    historic_rows = [
        row
        for row in rows
        if str(row["IdentifierValue"]).startswith("OLD")
    ]

    duplicate_rows = [
        row
        for row in rows
        if str(row["IdentifierValue"]).startswith("DUP")
    ]

    if len(historic_rows) != 150:
        raise ValueError(
            f"Expected 150 historic rows but found {len(historic_rows)}."
        )

    if len(duplicate_rows) != 20:
        raise ValueError(
            f"Expected 20 duplicate rows but found {len(duplicate_rows)}."
        )

    invalid_historic_rows = [
        int(row["PatientIdentifierId"])
        for row in historic_rows
        if bool(row["IsCurrent"])
        or row["EffectiveToDate"] is None
    ]

    if invalid_historic_rows:
        raise ValueError(
            "Historic identifiers are not correctly closed."
        )

    duplicate_groups: dict[str, set[int]] = {}

    for row in duplicate_rows:
        duplicate_groups.setdefault(
            str(row["IdentifierValue"]),
            set(),
        ).add(int(row["PatientId"]))

    if len(duplicate_groups) != 10:
        raise ValueError(
            "Expected 10 duplicate identifier groups."
        )

    invalid_groups = [
        identifier_value
        for identifier_value, patient_ids in duplicate_groups.items()
        if len(patient_ids) != 2
    ]

    if invalid_groups:
        raise ValueError(
            "Each duplicate identifier must belong to two patients."
        )

    print("Validated Stage 2 identifier IDs: 2001–2170.")
    print("Validated historic identifiers: 150.")
    print("Validated duplicate identifier rows: 20.")
    print("Validated duplicate scenarios: 10.")


def verify_database(
    cursor: pyodbc.Cursor,
) -> None:
    """Verify the target database and Stage 1 baseline."""

    cursor.execute(
        """
        SELECT
            DB_NAME() AS DatabaseName,
            @@SERVERNAME AS ServerName;
        """
    )

    row = cursor.fetchone()

    if row is None:
        raise RuntimeError(
            "Unable to verify the SQL Server target."
        )

    if str(row.DatabaseName) != "Aegis_Source":
        raise RuntimeError(
            f"Unexpected target database: {row.DatabaseName}"
        )

    print(f"Connected server: {row.ServerName}")
    print(f"Connected database: {row.DatabaseName}")

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientIdentifier;
        """
    )

    existing_count = int(cursor.fetchval())

    if existing_count != BASELINE_IDENTIFIER_COUNT:
        raise RuntimeError(
            "Stage 2 load requires exactly 2,000 existing Stage 1 "
            f"identifier rows. Current count: {existing_count}"
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.Patient;
        """
    )

    patient_count = int(cursor.fetchval())

    if patient_count != 1_000:
        raise RuntimeError(
            "Stage 2 load requires exactly 1,000 existing patients. "
            f"Current count: {patient_count}"
        )

    print("Verified Stage 1 database baseline.")


def validate_patient_references(
    cursor: pyodbc.Cursor,
    rows: list[dict[str, Any]],
) -> None:
    """Confirm every Stage 2 identifier references an existing patient."""

    patient_ids = sorted(
        {
            int(row["PatientId"])
            for row in rows
        }
    )

    placeholders = ", ".join(
        "?"
        for _ in patient_ids
    )

    cursor.execute(
        f"""
        SELECT PatientId
        FROM pas.Patient
        WHERE PatientId IN ({placeholders});
        """,
        patient_ids,
    )

    existing_patient_ids = {
        int(row.PatientId)
        for row in cursor.fetchall()
    }

    missing_patient_ids = (
        set(patient_ids) - existing_patient_ids
    )

    if missing_patient_ids:
        raise RuntimeError(
            "Stage 2 identifiers reference missing patients: "
            + ", ".join(
                str(patient_id)
                for patient_id in sorted(missing_patient_ids)
            )
        )

    print("Validated Stage 2 patient references.")


def insert_rows(
    cursor: pyodbc.Cursor,
    rows: list[dict[str, Any]],
) -> None:
    """Insert Stage 2 patient identifiers."""

    column_sql = ", ".join(
        f"[{column_name}]"
        for column_name in COLUMNS
    )

    placeholder_sql = ", ".join(
        "?"
        for _ in COLUMNS
    )

    insert_sql = (
        "INSERT INTO [pas].[PatientIdentifier] "
        f"({column_sql}) VALUES ({placeholder_sql});"
    )

    parameter_rows = [
        tuple(
            row[column_name]
            for column_name in COLUMNS
        )
        for row in rows
    ]

    identity_insert_enabled = False

    try:
        cursor.execute(
            "SET IDENTITY_INSERT [pas].[PatientIdentifier] ON;"
        )
        identity_insert_enabled = True

        print(
            f"Loading {len(rows)} Stage 2 rows into "
            "[pas].[PatientIdentifier]..."
        )

        cursor.fast_executemany = False
        cursor.executemany(
            insert_sql,
            parameter_rows,
        )

        print(
            f"Inserted {len(rows)} Stage 2 identifier rows."
        )
    finally:
        if identity_insert_enabled:
            cursor.execute(
                "SET IDENTITY_INSERT "
                "[pas].[PatientIdentifier] OFF;"
            )


def validate_database_result(
    cursor: pyodbc.Cursor,
) -> None:
    """Validate the final Stage 2 SQL Server state."""

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientIdentifier;
        """
    )

    final_count = int(cursor.fetchval())

    if final_count != EXPECTED_FINAL_IDENTIFIER_COUNT:
        raise RuntimeError(
            f"Expected {EXPECTED_FINAL_IDENTIFIER_COUNT} identifiers "
            f"after loading but found {final_count}."
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM
        (
            SELECT IdentifierValue
            FROM pas.PatientIdentifier
            WHERE IdentifierValue LIKE 'DUP%'
            GROUP BY IdentifierValue
            HAVING
                COUNT_BIG(*) = 2
                AND COUNT_BIG(DISTINCT PatientId) = 2
        ) AS DuplicateScenario;
        """
    )

    duplicate_scenario_count = int(cursor.fetchval())

    if duplicate_scenario_count != 10:
        raise RuntimeError(
            "Database does not contain the expected 10 duplicate "
            "identifier scenarios."
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientIdentifier
        WHERE IdentifierValue LIKE 'OLD%'
          AND IsCurrent = 0
          AND EffectiveToDate IS NOT NULL;
        """
    )

    historic_count = int(cursor.fetchval())

    if historic_count != 150:
        raise RuntimeError(
            "Database does not contain the expected 150 closed "
            "historic identifiers."
        )

    print(
        "Validated database identifier count: "
        f"{final_count}"
    )
    print(
        "Validated database historic identifiers: "
        f"{historic_count}"
    )
    print(
        "Validated database duplicate scenarios: "
        f"{duplicate_scenario_count}"
    )


def load_stage2_rows(
    rows: list[dict[str, Any]],
) -> None:
    """Load Stage 2 rows in one transaction."""

    connection = pyodbc.connect(
        build_connection_string(),
        autocommit=False,
    )

    try:
        cursor = connection.cursor()

        verify_database(cursor)
        validate_patient_references(
            cursor=cursor,
            rows=rows,
        )
        insert_rows(
            cursor=cursor,
            rows=rows,
        )
        validate_database_result(cursor)

        connection.commit()

        print(
            "Stage 2 patient-identity transaction committed successfully."
        )
    except Exception:
        connection.rollback()

        print(
            "Stage 2 patient-identity transaction rolled back."
        )

        raise
    finally:
        connection.close()


def main() -> None:
    """Validate and optionally load Stage 2 patient identifiers."""

    arguments = parse_arguments()
    config = GeneratorConfig()

    input_path = (
        config.pas_output_directory
        / "patient_identifier_stage2.csv"
    )

    print("Aegis Stage 2 patient-identity loader started.")
    print(
        "Mode: "
        + ("DATABASE LOAD" if arguments.load else "VALIDATION ONLY")
    )
    print(f"Input file: {input_path}")

    rows = read_stage2_rows(
        input_path=input_path,
    )

    validate_stage2_rows(rows)

    print(
        f"Validated additional Stage 2 rows: {len(rows)}"
    )

    if not arguments.load:
        print(
            "Validation completed successfully. "
            "No database changes were made."
        )
        return

    load_stage2_rows(rows)

    print(
        "Aegis Stage 2 patient-identity load completed successfully."
    )


if __name__ == "__main__":
    main()