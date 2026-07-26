"""Load generated Aegis patient-merge events into Aegis_Source."""

from __future__ import annotations

import argparse
import csv
import os
from datetime import datetime
from pathlib import Path
from typing import Any

import pyodbc

from synthetic_data.config import GeneratorConfig


EXPECTED_MERGE_COUNT = 25


COLUMNS = (
    "PatientMergeId",
    "SurvivingPatientId",
    "SupersededPatientId",
    "SurvivingIdentifierValue",
    "SupersededIdentifierValue",
    "MergeDateTime",
    "MergeReasonCode",
    "MergeReasonDescription",
    "SourceMessageControlId",
    "SourceSystemCode",
    "CreatedAtUtc",
    "UpdatedAtUtc",
)


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Validate or load generated Aegis patient merges into "
            "the Aegis_Source database."
        )
    )

    parser.add_argument(
        "--load",
        action="store_true",
        help="Load merge rows. Without this flag, validation only.",
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
        "PatientMergeId",
        "SurvivingPatientId",
        "SupersededPatientId",
    }:
        return int(raw_value)

    if column_name in {
        "MergeDateTime",
        "CreatedAtUtc",
        "UpdatedAtUtc",
    }:
        return datetime.fromisoformat(raw_value)

    return raw_value


def read_merge_rows(
    input_path: Path,
) -> list[dict[str, Any]]:
    """Read and structurally validate patient_merge.csv."""

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
                "patient_merge.csv columns do not match the expected "
                f"schema.\nExpected: {COLUMNS}\n"
                f"Actual:   {actual_columns}"
            )

        rows = [
            {
                column_name: convert_value(
                    raw_value=raw_row[column_name],
                    column_name=column_name,
                )
                for column_name in COLUMNS
            }
            for raw_row in reader
        ]

    if len(rows) != EXPECTED_MERGE_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_MERGE_COUNT} merge rows "
            f"but found {len(rows)}."
        )

    return rows


def validate_merge_rows(
    rows: list[dict[str, Any]],
) -> None:
    """Validate generated merge events before database access."""

    merge_ids = [
        int(row["PatientMergeId"])
        for row in rows
    ]

    if merge_ids != list(
        range(1, EXPECTED_MERGE_COUNT + 1)
    ):
        raise ValueError(
            "PatientMergeId values must be the continuous range 1–25."
        )

    message_control_ids = [
        str(row["SourceMessageControlId"])
        for row in rows
    ]

    if len(message_control_ids) != len(set(message_control_ids)):
        raise ValueError(
            "SourceMessageControlId values are not unique."
        )

    all_patient_ids: list[int] = []

    for row in rows:
        surviving_patient_id = int(
            row["SurvivingPatientId"]
        )
        superseded_patient_id = int(
            row["SupersededPatientId"]
        )

        if surviving_patient_id == superseded_patient_id:
            raise ValueError(
                f"PatientMergeId {row['PatientMergeId']} uses the same "
                "patient on both sides."
            )

        expected_surviving_identifier = (
            f"AEG{surviving_patient_id:07d}"
        )
        expected_superseded_identifier = (
            f"AEG{superseded_patient_id:07d}"
        )

        if (
            row["SurvivingIdentifierValue"]
            != expected_surviving_identifier
        ):
            raise ValueError(
                f"PatientMergeId {row['PatientMergeId']} has an "
                "unexpected surviving identifier."
            )

        if (
            row["SupersededIdentifierValue"]
            != expected_superseded_identifier
        ):
            raise ValueError(
                f"PatientMergeId {row['PatientMergeId']} has an "
                "unexpected superseded identifier."
            )

        all_patient_ids.extend(
            [
                surviving_patient_id,
                superseded_patient_id,
            ]
        )

    if len(all_patient_ids) != len(set(all_patient_ids)):
        raise ValueError(
            "A patient appears in more than one merge event."
        )

    print("Validated patient merge IDs: 1–25.")
    print("Validated unique message-control identifiers: 25.")
    print("Validated distinct survivor and superseded patients.")
    print("Validated hospital-number values against patient IDs.")


def verify_database(
    cursor: pyodbc.Cursor,
) -> None:
    """Verify the intended database and required baseline."""

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
        FROM pas.Patient;
        """
    )

    patient_count = int(cursor.fetchval())

    if patient_count != 1_000:
        raise RuntimeError(
            "Merge loading requires exactly 1,000 patients. "
            f"Current count: {patient_count}"
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientIdentifier;
        """
    )

    identifier_count = int(cursor.fetchval())

    if identifier_count != 2_170:
        raise RuntimeError(
            "Merge loading requires exactly 2,170 identifiers. "
            f"Current count: {identifier_count}"
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientMerge;
        """
    )

    existing_merge_count = int(cursor.fetchval())

    if existing_merge_count != 0:
        raise RuntimeError(
            "Initial merge loading requires an empty pas.PatientMerge table. "
            f"Current count: {existing_merge_count}"
        )

    print("Verified Stage 2 database baseline.")


def validate_patient_references(
    cursor: pyodbc.Cursor,
    rows: list[dict[str, Any]],
) -> None:
    """Confirm all merge patients and identifiers exist in SQL Server."""

    patient_ids = sorted(
        {
            int(row["SurvivingPatientId"])
            for row in rows
        }
        |
        {
            int(row["SupersededPatientId"])
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

    missing_patient_ids = set(patient_ids) - existing_patient_ids

    if missing_patient_ids:
        raise RuntimeError(
            "Merge rows reference missing patients: "
            + ", ".join(
                str(patient_id)
                for patient_id in sorted(missing_patient_ids)
            )
        )

    hospital_numbers = sorted(
        {
            str(row["SurvivingIdentifierValue"])
            for row in rows
        }
        |
        {
            str(row["SupersededIdentifierValue"])
            for row in rows
        }
    )

    identifier_placeholders = ", ".join(
        "?"
        for _ in hospital_numbers
    )

    cursor.execute(
        f"""
        SELECT IdentifierValue
        FROM pas.PatientIdentifier
        WHERE IdentifierTypeCode = 'HOSPITAL_NUMBER'
          AND IdentifierValue IN ({identifier_placeholders});
        """,
        hospital_numbers,
    )

    existing_identifier_values = {
        str(row.IdentifierValue)
        for row in cursor.fetchall()
    }

    missing_identifier_values = (
        set(hospital_numbers) - existing_identifier_values
    )

    if missing_identifier_values:
        raise RuntimeError(
            "Merge rows reference missing hospital identifiers: "
            + ", ".join(sorted(missing_identifier_values))
        )

    print("Validated merge patient references.")
    print("Validated merge hospital identifiers.")


def insert_merge_rows(
    cursor: pyodbc.Cursor,
    rows: list[dict[str, Any]],
) -> None:
    """Insert patient merge rows while preserving identity values."""

    column_sql = ", ".join(
        f"[{column_name}]"
        for column_name in COLUMNS
    )

    placeholder_sql = ", ".join(
        "?"
        for _ in COLUMNS
    )

    insert_sql = (
        "INSERT INTO [pas].[PatientMerge] "
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
            "SET IDENTITY_INSERT [pas].[PatientMerge] ON;"
        )
        identity_insert_enabled = True

        print(
            f"Loading {len(rows)} rows into [pas].[PatientMerge]..."
        )

        cursor.fast_executemany = False
        cursor.executemany(
            insert_sql,
            parameter_rows,
        )

        print(
            f"Inserted {len(rows)} patient merge rows."
        )
    finally:
        if identity_insert_enabled:
            cursor.execute(
                "SET IDENTITY_INSERT [pas].[PatientMerge] OFF;"
            )


def validate_database_result(
    cursor: pyodbc.Cursor,
) -> None:
    """Validate the loaded merge state."""

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientMerge;
        """
    )

    merge_count = int(cursor.fetchval())

    if merge_count != EXPECTED_MERGE_COUNT:
        raise RuntimeError(
            f"Expected {EXPECTED_MERGE_COUNT} merge rows "
            f"but found {merge_count}."
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(DISTINCT SourceMessageControlId)
        FROM pas.PatientMerge;
        """
    )

    message_count = int(cursor.fetchval())

    if message_count != EXPECTED_MERGE_COUNT:
        raise RuntimeError(
            "Loaded merge message-control identifiers are not unique."
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.PatientMerge
        WHERE SurvivingPatientId = SupersededPatientId;
        """
    )

    invalid_self_merge_count = int(cursor.fetchval())

    if invalid_self_merge_count != 0:
        raise RuntimeError(
            "Database contains invalid self-merge events."
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM
        (
            SELECT PatientId
            FROM
            (
                SELECT SurvivingPatientId AS PatientId
                FROM pas.PatientMerge

                UNION ALL

                SELECT SupersededPatientId AS PatientId
                FROM pas.PatientMerge
            ) AS MergePatient
            GROUP BY PatientId
            HAVING COUNT_BIG(*) > 1
        ) AS RepeatedMergePatient;
        """
    )

    repeated_patient_count = int(cursor.fetchval())

    if repeated_patient_count != 0:
        raise RuntimeError(
            "A patient appears in more than one loaded merge event."
        )

    print(
        f"Validated database patient merges: {merge_count}"
    )
    print(
        f"Validated unique merge messages: {message_count}"
    )
    print("Validated no self-merges.")
    print("Validated no repeated merge patients.")


def load_merge_rows(
    rows: list[dict[str, Any]],
) -> None:
    """Load merge events in one SQL Server transaction."""

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
        insert_merge_rows(
            cursor=cursor,
            rows=rows,
        )
        validate_database_result(cursor)

        connection.commit()

        print(
            "Patient-merge transaction committed successfully."
        )
    except Exception:
        connection.rollback()

        print(
            "Patient-merge transaction rolled back."
        )

        raise
    finally:
        connection.close()


def main() -> None:
    """Validate and optionally load generated patient merges."""

    arguments = parse_arguments()
    config = GeneratorConfig()

    input_path = (
        config.pas_output_directory
        / "patient_merge.csv"
    )

    print("Aegis patient-merge loader started.")
    print(
        "Mode: "
        + ("DATABASE LOAD" if arguments.load else "VALIDATION ONLY")
    )
    print(f"Input file: {input_path}")

    rows = read_merge_rows(
        input_path=input_path,
    )

    validate_merge_rows(rows)

    print(f"Validated patient merge rows: {len(rows)}")

    if not arguments.load:
        print(
            "Validation completed successfully. "
            "No database changes were made."
        )
        return

    load_merge_rows(rows)

    print(
        "Aegis patient-merge load completed successfully."
    )


if __name__ == "__main__":
    main()