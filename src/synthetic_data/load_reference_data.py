"""Load generated Aegis reference data into the Aegis_Source database."""

from __future__ import annotations

import argparse
import csv
import os
from datetime import date, datetime
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pyodbc

from synthetic_data.config import GeneratorConfig


@dataclass(frozen=True)
class DatasetDefinition:
    """Describe one generated reference dataset and its SQL target."""

    name: str
    schema_name: str
    table_name: str
    filename: str
    identity_column: str
    columns: tuple[str, ...]
    integer_columns: frozenset[str]


DATASETS: tuple[DatasetDefinition, ...] = (
    DatasetDefinition(
        name="organisation",
        schema_name="ref",
        table_name="Organisation",
        filename="organisation.csv",
        identity_column="OrganisationId",
        columns=(
            "OrganisationId",
            "OrganisationCode",
            "NationalOrganisationCode",
            "OrganisationName",
            "OrganisationTypeCode",
            "ParentOrganisationCode",
            "Postcode",
            "EffectiveFromDate",
            "EffectiveToDate",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "OrganisationId",
                "IsDeleted",
            }
        ),
    ),
    DatasetDefinition(
        name="site",
        schema_name="ref",
        table_name="Site",
        filename="site.csv",
        identity_column="SiteId",
        columns=(
            "SiteId",
            "OrganisationId",
            "SiteCode",
            "NationalSiteCode",
            "SiteName",
            "AddressLine1",
            "AddressLine2",
            "AddressLine3",
            "Postcode",
            "EffectiveFromDate",
            "EffectiveToDate",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "SiteId",
                "OrganisationId",
                "IsDeleted",
            }
        ),
    ),
    DatasetDefinition(
        name="specialty",
        schema_name="ref",
        table_name="Specialty",
        filename="specialty.csv",
        identity_column="SpecialtyId",
        columns=(
            "SpecialtyId",
            "SpecialtyCode",
            "NationalSpecialtyCode",
            "SpecialtyName",
            "SpecialtyTypeCode",
            "ParentSpecialtyCode",
            "EffectiveFromDate",
            "EffectiveToDate",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "SpecialtyId",
                "IsDeleted",
            }
        ),
    ),
    DatasetDefinition(
        name="consultant",
        schema_name="ref",
        table_name="Consultant",
        filename="consultant.csv",
        identity_column="ConsultantId",
        columns=(
            "ConsultantId",
            "OrganisationId",
            "MainSpecialtyId",
            "ConsultantCode",
            "NationalConsultantCode",
            "TitleCode",
            "FamilyName",
            "GivenName",
            "DisplayName",
            "EffectiveFromDate",
            "EffectiveToDate",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "ConsultantId",
                "OrganisationId",
                "MainSpecialtyId",
                "IsDeleted",
            }
        ),
    ),
    DatasetDefinition(
        name="ward",
        schema_name="ref",
        table_name="Ward",
        filename="ward.csv",
        identity_column="WardId",
        columns=(
            "WardId",
            "SiteId",
            "WardCode",
            "WardName",
            "WardTypeCode",
            "SpecialtyId",
            "BedCapacity",
            "EffectiveFromDate",
            "EffectiveToDate",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "WardId",
                "SiteId",
                "SpecialtyId",
                "BedCapacity",
                "IsDeleted",
            }
        ),
    ),
)


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Validate or load generated Aegis reference data into "
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
            "Delete existing reference rows before loading. "
            "Requires --load."
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
    integer_columns: frozenset[str],
) -> Any:
    """Convert one CSV value into a strongly typed pyodbc parameter."""

    if raw_value is None or raw_value == "":
        return None

    if column_name == "IsDeleted":
        return bool(int(raw_value))

    if column_name in integer_columns:
        return int(raw_value)

    if column_name.endswith("Date"):
        return date.fromisoformat(raw_value)

    if column_name in {
        "RecordCreatedAt",
        "RecordUpdatedAt",
    }:
        return datetime.fromisoformat(raw_value)

    return raw_value


def read_dataset(
    definition: DatasetDefinition,
    reference_directory: Path,
) -> list[dict[str, Any]]:
    """Read and validate one generated reference CSV file."""

    input_path = reference_directory / definition.filename

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
                    integer_columns=definition.integer_columns,
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


def validate_generated_files(
    reference_directory: Path,
) -> dict[str, list[dict[str, Any]]]:
    """Read and validate all generated reference datasets."""

    loaded_datasets: dict[str, list[dict[str, Any]]] = {}

    for definition in DATASETS:
        rows = read_dataset(
            definition=definition,
            reference_directory=reference_directory,
        )

        loaded_datasets[definition.name] = rows

        print(
            f"Validated {definition.filename}: "
            f"{len(rows)} rows"
        )

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
            "Reference data may only be loaded into Aegis_Source. "
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


def delete_existing_rows(
    cursor: pyodbc.Cursor,
) -> None:
    """Delete existing reference data in foreign-key-safe order."""

    delete_order = tuple(reversed(DATASETS))

    for definition in delete_order:
        qualified_table = (
            f"[{definition.schema_name}].[{definition.table_name}]"
        )

        cursor.execute(f"DELETE FROM {qualified_table};")

        print(
            f"Deleted existing rows: {qualified_table} "
            f"({cursor.rowcount})"
        )


def insert_dataset(
    cursor: pyodbc.Cursor,
    definition: DatasetDefinition,
    rows: list[dict[str, Any]],
) -> None:
    """Insert one reference dataset while preserving identity values."""

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
        tuple(row[column_name] for column_name in definition.columns)
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


def load_reference_data(
    datasets: dict[str, list[dict[str, Any]]],
    replace_existing: bool,
) -> None:
    """Load all reference datasets in one SQL Server transaction."""

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

        connection.commit()

        print("Reference-data transaction committed successfully.")
    except Exception:
        connection.rollback()

        print("Reference-data transaction rolled back.")

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

    print("Aegis reference-data loader started.")
    print(
        "Mode: "
        + ("DATABASE LOAD" if arguments.load else "VALIDATION ONLY")
    )
    print(
        f"Input directory: {config.reference_output_directory}"
    )

    datasets = validate_generated_files(
        reference_directory=config.reference_output_directory,
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

    load_reference_data(
        datasets=datasets,
        replace_existing=arguments.replace,
    )

    print("Aegis reference-data load completed successfully.")


if __name__ == "__main__":
    main()