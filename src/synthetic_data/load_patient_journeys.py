"""Load generated Aegis admitted-patient journeys into Aegis_Source."""

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
    """Describe one generated PAS activity dataset and its SQL target."""

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
    expected_count: int


DATASETS: tuple[DatasetDefinition, ...] = (
    DatasetDefinition(
        name="admission",
        schema_name="pas",
        table_name="Admission",
        filename="admission.csv",
        identity_column="AdmissionId",
        columns=(
            "AdmissionId",
            "PatientId",
            "OrganisationId",
            "SiteId",
            "AdmissionNumber",
            "PatientPathwayId",
            "AdmissionDateTime",
            "DischargeDateTime",
            "AdmissionMethodCode",
            "AdmissionSourceCode",
            "PatientClassificationCode",
            "IntendedManagementCode",
            "DischargeMethodCode",
            "DischargeDestinationCode",
            "AdministrativeCategoryCode",
            "LegalStatusCode",
            "AdmissionStatusCode",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "AdmissionId",
                "PatientId",
                "OrganisationId",
                "SiteId",
            }
        ),
        bit_columns=frozenset(
            {
                "IsDeleted",
            }
        ),
        date_columns=frozenset(),
        datetime_columns=frozenset(
            {
                "AdmissionDateTime",
                "DischargeDateTime",
                "RecordCreatedAt",
                "RecordUpdatedAt",
            }
        ),
        expected_count=1_600,
    ),
    DatasetDefinition(
        name="consultant_episode",
        schema_name="pas",
        table_name="ConsultantEpisode",
        filename="consultant_episode.csv",
        identity_column="ConsultantEpisodeId",
        columns=(
            "ConsultantEpisodeId",
            "AdmissionId",
            "EpisodeNumber",
            "EpisodeSequence",
            "ConsultantId",
            "MainSpecialtyId",
            "TreatmentSpecialtyId",
            "EpisodeStartDateTime",
            "EpisodeEndDateTime",
            "EpisodeStatusCode",
            "EpisodeTypeCode",
            "PatientClassificationCode",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "ConsultantEpisodeId",
                "AdmissionId",
                "EpisodeSequence",
                "ConsultantId",
                "MainSpecialtyId",
                "TreatmentSpecialtyId",
            }
        ),
        bit_columns=frozenset(
            {
                "IsDeleted",
            }
        ),
        date_columns=frozenset(),
        datetime_columns=frozenset(
            {
                "EpisodeStartDateTime",
                "EpisodeEndDateTime",
                "RecordCreatedAt",
                "RecordUpdatedAt",
            }
        ),
        expected_count=3_125,
    ),
    DatasetDefinition(
        name="diagnosis",
        schema_name="pas",
        table_name="Diagnosis",
        filename="diagnosis.csv",
        identity_column="DiagnosisId",
        columns=(
            "DiagnosisId",
            "ConsultantEpisodeId",
            "SourceDiagnosisId",
            "DiagnosisSequence",
            "IsPrimaryDiagnosis",
            "DiagnosisCode",
            "DiagnosisCodeSystem",
            "DiagnosisDescription",
            "DiagnosisDate",
            "PresentOnAdmissionCode",
            "LateralityCode",
            "DiagnosisStatusCode",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "DiagnosisId",
                "ConsultantEpisodeId",
                "DiagnosisSequence",
            }
        ),
        bit_columns=frozenset(
            {
                "IsPrimaryDiagnosis",
                "IsDeleted",
            }
        ),
        date_columns=frozenset(
            {
                "DiagnosisDate",
            }
        ),
        datetime_columns=frozenset(
            {
                "RecordCreatedAt",
                "RecordUpdatedAt",
            }
        ),
        expected_count=7_797,
    ),
    DatasetDefinition(
        name="procedure",
        schema_name="pas",
        table_name="Procedure",
        filename="procedure.csv",
        identity_column="ProcedureId",
        columns=(
            "ProcedureId",
            "ConsultantEpisodeId",
            "SourceProcedureId",
            "ProcedureSequence",
            "IsPrimaryProcedure",
            "ProcedureCode",
            "ProcedureCodeSystem",
            "ProcedureDescription",
            "ProcedureDateTime",
            "ProcedureSiteCode",
            "LateralityCode",
            "ProcedureStatusCode",
            "ConsultantId",
            "SiteId",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "ProcedureId",
                "ConsultantEpisodeId",
                "ProcedureSequence",
                "ConsultantId",
                "SiteId",
            }
        ),
        bit_columns=frozenset(
            {
                "IsPrimaryProcedure",
                "IsDeleted",
            }
        ),
        date_columns=frozenset(),
        datetime_columns=frozenset(
            {
                "ProcedureDateTime",
                "RecordCreatedAt",
                "RecordUpdatedAt",
            }
        ),
        expected_count=2_150,
    ),
    DatasetDefinition(
        name="ward_stay",
        schema_name="pas",
        table_name="WardStay",
        filename="ward_stay.csv",
        identity_column="WardStayId",
        columns=(
            "WardStayId",
            "AdmissionId",
            "WardId",
            "SourceWardStayId",
            "WardStaySequence",
            "WardStartDateTime",
            "WardEndDateTime",
            "AdmissionWardFlag",
            "DischargeWardFlag",
            "BedNumber",
            "BayCode",
            "WardStayStatusCode",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ),
        integer_columns=frozenset(
            {
                "WardStayId",
                "AdmissionId",
                "WardId",
                "WardStaySequence",
            }
        ),
        bit_columns=frozenset(
            {
                "AdmissionWardFlag",
                "DischargeWardFlag",
                "IsDeleted",
            }
        ),
        date_columns=frozenset(),
        datetime_columns=frozenset(
            {
                "WardStartDateTime",
                "WardEndDateTime",
                "RecordCreatedAt",
                "RecordUpdatedAt",
            }
        ),
        expected_count=3_211,
    ),
)


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Validate or load generated Aegis admitted-patient journeys "
            "into the Aegis_Source database."
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
            "Delete existing journey activity before loading. "
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
    """Read and structurally validate one generated PAS activity file."""

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

            if converted_row[definition.identity_column] is None:
                raise ValueError(
                    f"{definition.filename} row {row_number} has no "
                    f"{definition.identity_column} value."
                )

            rows.append(converted_row)

    if len(rows) != definition.expected_count:
        raise ValueError(
            f"{definition.filename} expected {definition.expected_count} "
            f"rows but contains {len(rows)}."
        )

    return rows


def validate_unique_column(
    dataset_name: str,
    rows: list[dict[str, Any]],
    column_name: str,
) -> None:
    """Confirm that a generated field contains unique values."""

    values = [
        row[column_name]
        for row in rows
    ]

    if len(values) != len(set(values)):
        raise ValueError(
            f"{dataset_name}.{column_name} contains duplicate values."
        )


def validate_file_relationships(
    datasets: dict[str, list[dict[str, Any]]],
) -> None:
    """Validate generated relationships and chronology before SQL access."""

    admissions = datasets["admission"]
    episodes = datasets["consultant_episode"]
    diagnoses = datasets["diagnosis"]
    procedures = datasets["procedure"]
    ward_stays = datasets["ward_stay"]

    validate_unique_column(
        "admission",
        admissions,
        "AdmissionId",
    )
    validate_unique_column(
        "admission",
        admissions,
        "AdmissionNumber",
    )
    validate_unique_column(
        "consultant_episode",
        episodes,
        "ConsultantEpisodeId",
    )
    validate_unique_column(
        "consultant_episode",
        episodes,
        "EpisodeNumber",
    )
    validate_unique_column(
        "diagnosis",
        diagnoses,
        "DiagnosisId",
    )
    validate_unique_column(
        "diagnosis",
        diagnoses,
        "SourceDiagnosisId",
    )
    validate_unique_column(
        "procedure",
        procedures,
        "ProcedureId",
    )
    validate_unique_column(
        "procedure",
        procedures,
        "SourceProcedureId",
    )
    validate_unique_column(
        "ward_stay",
        ward_stays,
        "WardStayId",
    )
    validate_unique_column(
        "ward_stay",
        ward_stays,
        "SourceWardStayId",
    )

    admission_lookup = {
        int(row["AdmissionId"]): row
        for row in admissions
    }

    episode_lookup = {
        int(row["ConsultantEpisodeId"]): row
        for row in episodes
    }

    for episode in episodes:
        admission_id = int(episode["AdmissionId"])

        if admission_id not in admission_lookup:
            raise ValueError(
                f"ConsultantEpisodeId "
                f"{episode['ConsultantEpisodeId']} references unknown "
                f"AdmissionId {admission_id}."
            )

        admission = admission_lookup[admission_id]

        admission_start = admission["AdmissionDateTime"]
        admission_end = (
            admission["DischargeDateTime"]
            or datetime(2026, 7, 26, 10, 0, 0)
        )
        episode_start = episode["EpisodeStartDateTime"]
        episode_end = (
            episode["EpisodeEndDateTime"]
            or datetime(2026, 7, 26, 10, 0, 0)
        )

        if not (
            admission_start
            <= episode_start
            <= episode_end
            <= admission_end
        ):
            raise ValueError(
                f"ConsultantEpisodeId "
                f"{episode['ConsultantEpisodeId']} is outside its admission."
            )

    for diagnosis in diagnoses:
        episode_id = int(
            diagnosis["ConsultantEpisodeId"]
        )

        if episode_id not in episode_lookup:
            raise ValueError(
                f"DiagnosisId {diagnosis['DiagnosisId']} references "
                f"unknown ConsultantEpisodeId {episode_id}."
            )

        episode = episode_lookup[episode_id]

        episode_start_date = episode[
            "EpisodeStartDateTime"
        ].date()

        episode_end_date = (
            episode["EpisodeEndDateTime"].date()
            if episode["EpisodeEndDateTime"] is not None
            else date(2026, 7, 26)
        )

        if not (
            episode_start_date
            <= diagnosis["DiagnosisDate"]
            <= episode_end_date
        ):
            raise ValueError(
                f"DiagnosisId {diagnosis['DiagnosisId']} is outside "
                "its consultant episode."
            )

    for procedure in procedures:
        episode_id = int(
            procedure["ConsultantEpisodeId"]
        )

        if episode_id not in episode_lookup:
            raise ValueError(
                f"ProcedureId {procedure['ProcedureId']} references "
                f"unknown ConsultantEpisodeId {episode_id}."
            )

        episode = episode_lookup[episode_id]

        episode_end = (
            episode["EpisodeEndDateTime"]
            or datetime(2026, 7, 26, 10, 0, 0)
        )

        if not (
            episode["EpisodeStartDateTime"]
            <= procedure["ProcedureDateTime"]
            <= episode_end
        ):
            raise ValueError(
                f"ProcedureId {procedure['ProcedureId']} is outside "
                "its consultant episode."
            )

    for ward_stay in ward_stays:
        admission_id = int(ward_stay["AdmissionId"])

        if admission_id not in admission_lookup:
            raise ValueError(
                f"WardStayId {ward_stay['WardStayId']} references "
                f"unknown AdmissionId {admission_id}."
            )

        admission = admission_lookup[admission_id]

        admission_end = (
            admission["DischargeDateTime"]
            or datetime(2026, 7, 26, 10, 0, 0)
        )

        ward_end = (
            ward_stay["WardEndDateTime"]
            or datetime(2026, 7, 26, 10, 0, 0)
        )

        if not (
            admission["AdmissionDateTime"]
            <= ward_stay["WardStartDateTime"]
            <= ward_end
            <= admission_end
        ):
            raise ValueError(
                f"WardStayId {ward_stay['WardStayId']} is outside "
                "its admission."
            )

    print("Validated file-level uniqueness.")
    print("Validated PAS activity foreign-key relationships.")
    print("Validated PAS activity chronology.")


def validate_generated_files(
    input_directory: Path,
) -> dict[str, list[dict[str, Any]]]:
    """Read and validate all generated PAS activity datasets."""

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

    validate_file_relationships(
        datasets=loaded_datasets,
    )

    return loaded_datasets


def verify_database_target(
    cursor: pyodbc.Cursor,
) -> None:
    """Confirm the intended database and required patient baseline."""

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

    if str(row.DatabaseName) != "Aegis_Source":
        raise RuntimeError(
            f"Unexpected target database: {row.DatabaseName}"
        )

    print(f"Connected server: {row.ServerName}")
    print(f"Connected database: {row.DatabaseName}")

    cursor.execute(
        "SELECT COUNT_BIG(*) FROM pas.Patient;"
    )
    patient_count = int(cursor.fetchval())

    cursor.execute(
        "SELECT COUNT_BIG(*) FROM pas.PatientIdentifier;"
    )
    identifier_count = int(cursor.fetchval())

    cursor.execute(
        "SELECT COUNT_BIG(*) FROM pas.PatientMerge;"
    )
    merge_count = int(cursor.fetchval())

    if patient_count != 1_000:
        raise RuntimeError(
            f"Expected 1,000 patients but found {patient_count}."
        )

    if identifier_count != 2_170:
        raise RuntimeError(
            f"Expected 2,170 identifiers but found {identifier_count}."
        )

    if merge_count != 25:
        raise RuntimeError(
            f"Expected 25 patient merges but found {merge_count}."
        )

    print("Verified patient and identity database baseline.")


def verify_target_tables(
    cursor: pyodbc.Cursor,
) -> None:
    """Confirm that all five PAS activity target tables exist."""

    for definition in DATASETS:
        qualified_name = (
            f"{definition.schema_name}.{definition.table_name}"
        )

        cursor.execute(
            "SELECT OBJECT_ID(?, 'U');",
            qualified_name,
        )

        if cursor.fetchval() is None:
            raise RuntimeError(
                f"Required target table does not exist: {qualified_name}"
            )

        print(f"Verified target table: {qualified_name}")


def verify_reference_keys(
    cursor: pyodbc.Cursor,
    datasets: dict[str, list[dict[str, Any]]],
) -> None:
    """Confirm all generated patient and reference keys exist."""

    checks = (
        (
            "patient",
            "pas.Patient",
            "PatientId",
            {
                int(row["PatientId"])
                for row in datasets["admission"]
            },
        ),
        (
            "organisation",
            "ref.Organisation",
            "OrganisationId",
            {
                int(row["OrganisationId"])
                for row in datasets["admission"]
            },
        ),
        (
            "site",
            "ref.Site",
            "SiteId",
            {
                int(row["SiteId"])
                for row in datasets["admission"]
            }
            | {
                int(row["SiteId"])
                for row in datasets["procedure"]
            },
        ),
        (
            "consultant",
            "ref.Consultant",
            "ConsultantId",
            {
                int(row["ConsultantId"])
                for row in datasets["consultant_episode"]
            }
            | {
                int(row["ConsultantId"])
                for row in datasets["procedure"]
            },
        ),
        (
            "specialty",
            "ref.Specialty",
            "SpecialtyId",
            {
                int(row["MainSpecialtyId"])
                for row in datasets["consultant_episode"]
            }
            | {
                int(row["TreatmentSpecialtyId"])
                for row in datasets["consultant_episode"]
            },
        ),
        (
            "ward",
            "ref.Ward",
            "WardId",
            {
                int(row["WardId"])
                for row in datasets["ward_stay"]
            },
        ),
    )

    for (
        key_name,
        table_name,
        column_name,
        expected_values,
    ) in checks:
        placeholders = ", ".join(
            "?"
            for _ in expected_values
        )

        cursor.execute(
            f"""
            SELECT [{column_name}]
            FROM {table_name}
            WHERE [{column_name}] IN ({placeholders});
            """,
            sorted(expected_values),
        )

        actual_values = {
            int(row[0])
            for row in cursor.fetchall()
        }

        missing_values = expected_values - actual_values

        if missing_values:
            raise RuntimeError(
                f"Generated data references missing {key_name} values: "
                + ", ".join(
                    str(value)
                    for value in sorted(missing_values)
                )
            )

        print(
            f"Validated database {key_name} references: "
            f"{len(expected_values)} distinct values."
        )


def verify_initial_or_replace_state(
    cursor: pyodbc.Cursor,
    replace_existing: bool,
) -> None:
    """Check whether activity tables are empty or eligible for replacement."""

    existing_counts: dict[str, int] = {}

    for definition in DATASETS:
        qualified_table = (
            f"[{definition.schema_name}].[{definition.table_name}]"
        )

        cursor.execute(
            f"SELECT COUNT_BIG(*) FROM {qualified_table};"
        )

        existing_counts[definition.name] = int(
            cursor.fetchval()
        )

    populated = {
        name: count
        for name, count in existing_counts.items()
        if count > 0
    }

    if populated and not replace_existing:
        details = ", ".join(
            f"{name}={count}"
            for name, count in populated.items()
        )

        raise RuntimeError(
            "Initial journey load requires empty activity tables. "
            f"Existing rows: {details}. Use --replace only when intended."
        )

    if replace_existing:
        print("Existing PAS activity will be replaced.")
    else:
        print("Verified PAS activity tables are empty.")


def delete_existing_rows(
    cursor: pyodbc.Cursor,
) -> None:
    """Delete existing PAS activity in foreign-key-safe order."""

    delete_order = (
        DATASETS[2],  # Diagnosis
        DATASETS[3],  # Procedure
        DATASETS[4],  # WardStay
        DATASETS[1],  # ConsultantEpisode
        DATASETS[0],  # Admission
    )

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
    """Insert one activity dataset while preserving identity values."""

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
) -> None:
    """Confirm loaded SQL Server counts match expected journey totals."""

    for definition in DATASETS:
        qualified_table = (
            f"[{definition.schema_name}].[{definition.table_name}]"
        )

        cursor.execute(
            f"SELECT COUNT_BIG(*) FROM {qualified_table};"
        )

        actual_count = int(cursor.fetchval())

        if actual_count != definition.expected_count:
            raise RuntimeError(
                f"{qualified_table} expected {definition.expected_count} "
                f"rows but contains {actual_count}."
            )

        print(
            f"Validated database count: {qualified_table} "
            f"= {actual_count}"
        )


def validate_database_relationships(
    cursor: pyodbc.Cursor,
) -> None:
    """Validate loaded relationships and operational journey rules."""

    validation_queries = (
        (
            "orphan consultant episodes",
            """
            SELECT COUNT_BIG(*)
            FROM pas.ConsultantEpisode AS ce
            LEFT JOIN pas.Admission AS a
                ON a.AdmissionId = ce.AdmissionId
            WHERE a.AdmissionId IS NULL;
            """,
        ),
        (
            "orphan diagnoses",
            """
            SELECT COUNT_BIG(*)
            FROM pas.Diagnosis AS d
            LEFT JOIN pas.ConsultantEpisode AS ce
                ON ce.ConsultantEpisodeId = d.ConsultantEpisodeId
            WHERE ce.ConsultantEpisodeId IS NULL;
            """,
        ),
        (
            "orphan procedures",
            """
            SELECT COUNT_BIG(*)
            FROM pas.[Procedure] AS p
            LEFT JOIN pas.ConsultantEpisode AS ce
                ON ce.ConsultantEpisodeId = p.ConsultantEpisodeId
            WHERE ce.ConsultantEpisodeId IS NULL;
            """,
        ),
        (
            "orphan ward stays",
            """
            SELECT COUNT_BIG(*)
            FROM pas.WardStay AS ws
            LEFT JOIN pas.Admission AS a
                ON a.AdmissionId = ws.AdmissionId
            WHERE a.AdmissionId IS NULL;
            """,
        ),
        (
            "invalid admission chronology",
            """
            SELECT COUNT_BIG(*)
            FROM pas.Admission
            WHERE DischargeDateTime < AdmissionDateTime;
            """,
        ),
        (
            "open admissions with discharge datetimes",
            """
            SELECT COUNT_BIG(*)
            FROM pas.Admission
            WHERE AdmissionStatusCode = 'OPEN'
              AND DischargeDateTime IS NOT NULL;
            """,
        ),
        (
            "discharged admissions without discharge datetimes",
            """
            SELECT COUNT_BIG(*)
            FROM pas.Admission
            WHERE AdmissionStatusCode = 'DISCHARGED'
              AND DischargeDateTime IS NULL;
            """,
        ),
        (
            "invalid episode chronology",
            """
            SELECT COUNT_BIG(*)
            FROM pas.ConsultantEpisode AS ce
            INNER JOIN pas.Admission AS a
                ON a.AdmissionId = ce.AdmissionId
            WHERE ce.EpisodeStartDateTime < a.AdmissionDateTime
               OR (
                    a.DischargeDateTime IS NOT NULL
                    AND ce.EpisodeEndDateTime > a.DischargeDateTime
               )
               OR ce.EpisodeEndDateTime < ce.EpisodeStartDateTime;
            """,
        ),
        (
            "invalid ward-stay chronology",
            """
            SELECT COUNT_BIG(*)
            FROM pas.WardStay AS ws
            INNER JOIN pas.Admission AS a
                ON a.AdmissionId = ws.AdmissionId
            WHERE ws.WardStartDateTime < a.AdmissionDateTime
               OR (
                    a.DischargeDateTime IS NOT NULL
                    AND ws.WardEndDateTime > a.DischargeDateTime
               )
               OR ws.WardEndDateTime < ws.WardStartDateTime;
            """,
        ),
    )

    for validation_name, query in validation_queries:
        cursor.execute(query)
        failure_count = int(cursor.fetchval())

        if failure_count != 0:
            raise RuntimeError(
                f"Database validation failed for {validation_name}: "
                f"{failure_count} rows."
            )

        print(
            f"Validated database {validation_name}: 0."
        )

    cursor.execute(
        """
        SELECT COUNT_BIG(*)
        FROM pas.Admission
        WHERE AdmissionStatusCode = 'OPEN';
        """
    )

    open_admission_count = int(cursor.fetchval())

    if open_admission_count != 192:
        raise RuntimeError(
            f"Expected 192 open admissions but found "
            f"{open_admission_count}."
        )

    print(
        f"Validated database open admissions: "
        f"{open_admission_count}"
    )


def load_patient_journeys(
    datasets: dict[str, list[dict[str, Any]]],
    replace_existing: bool,
) -> None:
    """Load all valid patient journeys in one SQL Server transaction."""

    connection = pyodbc.connect(
        build_connection_string(),
        autocommit=False,
    )

    try:
        cursor = connection.cursor()

        verify_database_target(cursor)
        verify_target_tables(cursor)
        verify_reference_keys(
            cursor=cursor,
            datasets=datasets,
        )
        verify_initial_or_replace_state(
            cursor=cursor,
            replace_existing=replace_existing,
        )

        if replace_existing:
            delete_existing_rows(cursor)

        for definition in DATASETS:
            insert_dataset(
                cursor=cursor,
                definition=definition,
                rows=datasets[definition.name],
            )

        validate_database_counts(cursor)
        validate_database_relationships(cursor)

        connection.commit()

        print(
            "Patient-journey transaction committed successfully."
        )
    except Exception:
        connection.rollback()

        print(
            "Patient-journey transaction rolled back."
        )

        raise
    finally:
        connection.close()


def main() -> None:
    """Validate generated files and optionally load patient journeys."""

    arguments = parse_arguments()
    config = GeneratorConfig()

    if arguments.replace and not arguments.load:
        raise ValueError(
            "--replace may only be used together with --load."
        )

    print("Aegis patient-journey loader started.")
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

    load_patient_journeys(
        datasets=datasets,
        replace_existing=arguments.replace,
    )

    print(
        "Aegis patient-journey load completed successfully."
    )


if __name__ == "__main__":
    main()