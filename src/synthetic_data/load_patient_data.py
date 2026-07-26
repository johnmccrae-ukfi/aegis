"""Load generated Aegis patient data into the Aegis_Source database."""

from __future__ import annotations

import argparse
import csv
import os
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any

import pyodbc

from synthetic_data.config import GeneratorConfig


@dataclass(frozen=True)
class DatasetDefinition:
    """Describe one generated patient dataset and its SQL target."""

    name: str
    schema_name: str
    table_name: str
    filename: str
    identity_column: str
    columns: tuple[str, ...]
    integer_columns: frozenset[str]
    bit_columns: frozenset[str]
    date_columns: frozenset[str]
    datetime_columns: frozenset[str]


DATASETS: tuple[DatasetDefinition, ...] = (
    DatasetDefinition(
        name="patient",
        schema_name="pas",
        table_name="Patient",
        filename="patient.csv",
        identity_column="PatientId",
        columns=(
            "PatientId",
            "HospitalNumber",
            "NhsNumber",
            "NhsNumberStatusCode",
            "FamilyName",
            "GivenName",
            "MiddleNames",
            "TitleCode",
            "DateOfBirth",
            "SexCode",
            "AddressLine1",
            "AddressLine2",
            "AddressLine3",
            "Postcode",
            "RegisteredGpCode",
            "RegisteredPracticeCode",
            "DateOfDeath",
            "PatientStatusCode",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "PatientId",
            }
        ),
        bit_columns=frozenset(
            {
                "IsDeleted",
            }
        ),
        date_columns=frozenset(
            {
                "DateOfBirth",
                "DateOfDeath",
            }
        ),
        datetime_columns=frozenset(
            {
                "RecordCreatedAt",
                "RecordUpdatedAt",
            }
        ),
    ),
    DatasetDefinition(
        name="patient_identifier",
        schema_name="pas",
        table_name="PatientIdentifier",
        filename="patient_identifier.csv",
        identity_column="PatientIdentifierId",
        columns=(
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
        ),
        integer_columns=frozenset(
            {
                "PatientIdentifierId",
                "PatientId",
            }
        ),
        bit_columns=frozenset(
            {
                "IsCurrent",
            }
        ),
        date_columns=frozenset(
            {
                "EffectiveFromDate",
                "EffectiveToDate",
            }
        ),
        datetime_columns=frozenset(
            {
                "CreatedAtUtc",
                "UpdatedAtUtc",
            }
        ),
    ),
)


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Validate or load generated Aegis patient data into "
            "the Aegis_Source database."
        )
    )

    parser.add_argument(
        "--load",
        action="store_true",
        help="Load data into SQL Server. Without this flag, validation only.",
    )

    parser.add_argument(
        "--replace",
        action="store_true",
        help=(
            "Delete existing patient-identifier and patient rows before "
            "loading. Requires --load."
        ),
    )

    return parser.parse_args()


def build_connection_string() -> str:
    """Build the SQL Server connection string from environment variables."""

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
    definition: DatasetDefinition,
) -> Any:
    """Convert one CSV value into a strongly typed pyodbc parameter."""

    if raw_value is None or raw_value == "":
        return None

    if column_name in definition.bit_columns:
        return bool(int(raw_value))

    if column_name in definition.integer_columns:
        return int(raw_value)

    if column_name in definition.date_columns:
        return date.fromisoformat(raw_value)

    if column_name in definition.datetime_columns:
        return datetime.fromisoformat(raw_value)

    return raw_value


def read_dataset(
    definition: DatasetDefinition,
    input_directory: Path,
) -> list[dict[str, Any]]:
    """Read and structurally validate one generated patient CSV file."""

    input_path = input_directory / definition.filename

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

        if actual_columns != definition.columns:
            raise ValueError(
                f"{definition.filename} columns do not match the expected "
                f"schema.\nExpected: {definition.columns}\n"
                f"Actual:   {actual_columns}"
            )

        rows: list[dict[str, Any]] = []

        for row_number, raw_row in enumerate(reader, start=2):
            converted_row = {
                column_name: convert_value(
                    raw_value=raw_row[column_name],
                    column_name=column_name,
                    definition=definition,
                )
                for column_name in definition.columns
            }

            identity_value = converted_row[definition.identity_column]

            if identity_value is None:
                raise ValueError(
                    f"{definition.filename} row {row_number} has no "
                    f"{definition.identity_column} value."
                )

            rows.append(converted_row)

    if not rows:
        raise ValueError(
            f"{definition.filename} contains no data rows."
        )

    return rows


def validate_unique_column(
    dataset_name: str,
    rows: list[dict[str, Any]],
    column_name: str,
) -> None:
    """Confirm that one generated column contains no duplicate values."""

    values = [
        row[column_name]
        for row in rows
    ]

    if len(values) != len(set(values)):
        raise ValueError(
            f"{dataset_name}.{column_name} contains duplicate values."
        )


def validate_patient_relationships(
    datasets: dict[str, list[dict[str, Any]]],
) -> None:
    """Validate relationships and identifier coverage before loading."""

    patients = datasets["patient"]
    identifiers = datasets["patient_identifier"]

    validate_unique_column(
        dataset_name="patient",
        rows=patients,
        column_name="PatientId",
    )
    validate_unique_column(
        dataset_name="patient",
        rows=patients,
        column_name="HospitalNumber",
    )
    validate_unique_column(
        dataset_name="patient",
        rows=patients,
        column_name="NhsNumber",
    )
    validate_unique_column(
        dataset_name="patient_identifier",
        rows=identifiers,
        column_name="PatientIdentifierId",
    )

    patient_ids = {
        int(patient["PatientId"])
        for patient in patients
    }

    orphan_identifier_ids = [
        int(identifier["PatientIdentifierId"])
        for identifier in identifiers
        if int(identifier["PatientId"]) not in patient_ids
    ]

    if orphan_identifier_ids:
        raise ValueError(
            "Patient identifiers reference unknown patients: "
            + ", ".join(
                str(identifier_id)
                for identifier_id in orphan_identifier_ids[:20]
            )
        )

    identifier_pairs = [
        (
            int(identifier["PatientId"]),
            str(identifier["IdentifierTypeCode"]),
        )
        for identifier in identifiers
    ]

    if len(identifier_pairs) != len(set(identifier_pairs)):
        raise ValueError(
            "Stage 1 contains duplicate patient and identifier-type pairs."
        )

    expected_identifier_count = len(patients) * 2

    if len(identifiers) != expected_identifier_count:
        raise ValueError(
            f"Expected {expected_identifier_count} patient identifiers "
            f"but found {len(identifiers)}."
        )

    identifiers_by_patient: dict[int, set[str]] = {}

    for identifier in identifiers:
        patient_id = int(identifier["PatientId"])
        identifier_type = str(identifier["IdentifierTypeCode"])

        identifiers_by_patient.setdefault(
            patient_id,
            set(),
        ).add(identifier_type)

    expected_types = {
        "HOSPITAL_NUMBER",
        "NHS_NUMBER",
    }

    invalid_patient_ids = [
        patient_id
        for patient_id in sorted(patient_ids)
        if identifiers_by_patient.get(patient_id) != expected_types
    ]

    if invalid_patient_ids:
        raise ValueError(
            "Patients do not have exactly the expected two Stage 1 "
            "identifier types: "
            + ", ".join(
                str(patient_id)
                for patient_id in invalid_patient_ids[:20]
            )
        )

    patient_lookup = {
        int(patient["PatientId"]): patient
        for patient in patients
    }

    mismatched_identifiers: list[int] = []

    for identifier in identifiers:
        patient_id = int(identifier["PatientId"])
        patient = patient_lookup[patient_id]
        identifier_type = str(identifier["IdentifierTypeCode"])
        identifier_value = str(identifier["IdentifierValue"])

        if identifier_type == "HOSPITAL_NUMBER":
            expected_value = str(patient["HospitalNumber"])
        elif identifier_type == "NHS_NUMBER":
            expected_value = str(patient["NhsNumber"])
        else:
            mismatched_identifiers.append(
                int(identifier["PatientIdentifierId"])
            )
            continue

        if identifier_value != expected_value:
            mismatched_identifiers.append(
                int(identifier["PatientIdentifierId"])
            )

    if mismatched_identifiers:
        raise ValueError(
            "Patient identifier values do not match pas.Patient values: "
            + ", ".join(
                str(identifier_id)
                for identifier_id in mismatched_identifiers[:20]
            )
        )


def validate_generated_files(
    input_directory: Path,
) -> dict[str, list[dict[str, Any]]]:
    """Read and validate all generated patient datasets."""

    loaded_datasets: dict[str, list[dict[str, Any]]] = {}

    for definition in DATASETS:
        rows = read_dataset(
            definition=definition,
            input_directory=input_directory,
        )

        loaded_datasets[definition.name] = rows

        print(
            f"Validated {definition.filename}: "
            f"{len(rows)} rows"
        )

    validate_patient_relationships(
        datasets=loaded_datasets,
    )

    print("Validated patient and identifier relationships.")

    return loaded_datasets


def verify_database_target(
    cursor: pyodbc.Cursor,
) -> None:
    """Confirm that the connection points to the intended Aegis database."""

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
            "SQL Server did not return the current database identity."
        )

    database_name = str(row.DatabaseName)
    server_name = str(row.ServerName)

    if database_name != "Aegis_Source":
        raise RuntimeError(
            "Patient data may only be loaded into Aegis_Source. "
            f"Connected database: {database_name}"
        )

    print(f"Connected server: {server_name}")
    print(f"Connected database: {database_name}")


def verify_target_tables(
    cursor: pyodbc.Cursor,
) -> None:
    """Confirm that all expected SQL Server target tables exist."""

    for definition in DATASETS:
        qualified_name = (
            f"{definition.schema_name}.{definition.table_name}"
        )

        cursor.execute(
            "SELECT OBJECT_ID(?, 'U');",
            qualified_name,
        )

        object_id = cursor.fetchval()

        if object_id is None:
            raise RuntimeError(
                f"Required target table does not exist: {qualified_name}"
            )

        print(f"Verified target table: {qualified_name}")


def verify_replace_is_safe(
    cursor: pyodbc.Cursor,
) -> None:
    """
    Confirm that patient rows have no dependent PAS activity before deletion.

    Stage 1 replacement is safe only before admissions and merge data exist.
    """

    dependent_tables = (
        "pas.Admission",
        "pas.PatientMerge",
    )

    populated_tables: list[str] = []

    for table_name in dependent_tables:
        cursor.execute(
            f"SELECT COUNT_BIG(*) FROM {table_name};"
        )

        row_count = int(cursor.fetchval())

        if row_count > 0:
            populated_tables.append(
                f"{table_name} ({row_count})"
            )

    if populated_tables:
        raise RuntimeError(
            "Patient replacement is blocked because dependent PAS data exists: "
            + ", ".join(populated_tables)
        )


def delete_existing_rows(
    cursor: pyodbc.Cursor,
) -> None:
    """Delete existing patient data in foreign-key-safe order."""

    delete_order = tuple(reversed(DATASETS))

    for definition in delete_order:
        qualified_table = (
            f"[{definition.schema_name}].[{definition.table_name}]"
        )

        cursor.execute(
            f"DELETE FROM {qualified_table};"
        )

        print(
            f"Deleted existing rows: {qualified_table} "
            f"({cursor.rowcount})"
        )


def insert_dataset(
    cursor: pyodbc.Cursor,
    definition: DatasetDefinition,
    rows: list[dict[str, Any]],
) -> None:
    """Insert one patient dataset while preserving identity values."""

    qualified_table = (
        f"[{definition.schema_name}].[{definition.table_name}]"
    )

    column_sql = ", ".join(
        f"[{column_name}]"
        for column_name in definition.columns
    )

    placeholder_sql = ", ".join(
        "?"
        for _ in definition.columns
    )

    insert_sql = (
        f"INSERT INTO {qualified_table} ({column_sql}) "
        f"VALUES ({placeholder_sql});"
    )

    parameter_rows = [
        tuple(
            row[column_name]
            for column_name in definition.columns
        )
        for row in rows
    ]

    identity_insert_enabled = False

    try:
        cursor.execute(
            f"SET IDENTITY_INSERT {qualified_table} ON;"
        )
        identity_insert_enabled = True

        print(
            f"Loading {len(rows)} rows into {qualified_table}..."
        )

        cursor.fast_executemany = False

        cursor.executemany(
            insert_sql,
            parameter_rows,
        )

        print(
            f"Inserted {len(rows)} rows: {qualified_table}"
        )
    finally:
        if identity_insert_enabled:
            cursor.execute(
                f"SET IDENTITY_INSERT {qualified_table} OFF;"
            )


def validate_database_counts(
    cursor: pyodbc.Cursor,
    datasets: dict[str, list[dict[str, Any]]],
) -> None:
    """Confirm SQL Server row counts match generated file counts."""

    for definition in DATASETS:
        qualified_table = (
            f"[{definition.schema_name}].[{definition.table_name}]"
        )

        cursor.execute(
            f"SELECT COUNT_BIG(*) FROM {qualified_table};"
        )

        actual_count = int(cursor.fetchval())
        expected_count = len(datasets[definition.name])

        if actual_count != expected_count:
            raise RuntimeError(
                f"{qualified_table} expected {expected_count} rows "
                f"but contains {actual_count}."
            )

        print(
            f"Validated database count: {qualified_table} "
            f"= {actual_count}"
        )


def validate_database_identifier_coverage(
    cursor: pyodbc.Cursor,
) -> None:
    """Confirm every loaded patient has the expected Stage 1 identifiers."""

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM
        (
            SELECT
                p.PatientId
            FROM pas.Patient AS p
            LEFT JOIN pas.PatientIdentifier AS pi
                ON pi.PatientId = p.PatientId
               AND pi.IsCurrent = 1
               AND pi.IdentifierTypeCode IN
               (
                   'HOSPITAL_NUMBER',
                   'NHS_NUMBER'
               )
            GROUP BY
                p.PatientId
            HAVING
                COUNT_BIG(pi.PatientIdentifierId) <> 2
                OR COUNT_BIG(
                    DISTINCT pi.IdentifierTypeCode
                ) <> 2
        ) AS InvalidPatient;
        """
    )

    invalid_patient_count = int(cursor.fetchval())

    if invalid_patient_count != 0:
        raise RuntimeError(
            f"{invalid_patient_count} loaded patients do not have exactly "
            "one current hospital identifier and one current NHS identifier."
        )

    print(
        "Validated database identifier coverage: "
        "two current identifiers per patient."
    )


def load_patient_data(
    datasets: dict[str, list[dict[str, Any]]],
    replace_existing: bool,
) -> None:
    """Load patient datasets in one SQL Server transaction."""

    connection_string = build_connection_string()

    connection = pyodbc.connect(
        connection_string,
        autocommit=False,
    )

    try:
        cursor = connection.cursor()

        verify_database_target(cursor)
        verify_target_tables(cursor)

        if replace_existing:
            verify_replace_is_safe(cursor)
            delete_existing_rows(cursor)

        for definition in DATASETS:
            insert_dataset(
                cursor=cursor,
                definition=definition,
                rows=datasets[definition.name],
            )

        validate_database_counts(
            cursor=cursor,
            datasets=datasets,
        )

        validate_database_identifier_coverage(
            cursor=cursor,
        )

        connection.commit()

        print("Patient-data transaction committed successfully.")
    except Exception:
        connection.rollback()

        print("Patient-data transaction rolled back.")

        raise
    finally:
        connection.close()


def main() -> None:
    """Validate generated files and optionally load them into SQL Server."""

    arguments = parse_arguments()
    config = GeneratorConfig()

    if arguments.replace and not arguments.load:
        raise ValueError(
            "--replace may only be used together with --load."
        )

    print("Aegis patient-data loader started.")
    print(
        "Mode: "
        + ("DATABASE LOAD" if arguments.load else "VALIDATION ONLY")
    )
    print(
        f"Input directory: {config.pas_output_directory}"
    )

    datasets = validate_generated_files(
        input_directory=config.pas_output_directory,
    )

    total_rows = sum(
        len(rows)
        for rows in datasets.values()
    )

    print(f"Validated total rows: {total_rows}")

    if not arguments.load:
        print(
            "Validation completed successfully. "
            "No database changes were made."
        )
        return

    load_patient_data(
        datasets=datasets,
        replace_existing=arguments.replace,
    )

    print("Aegis patient-data load completed successfully.")


if __name__ == "__main__":
    main()