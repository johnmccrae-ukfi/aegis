"""Generate deterministic Aegis patient-merge events."""

from __future__ import annotations

import csv
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from synthetic_data.config import GeneratorConfig
from synthetic_data.validation.generation_validation import (
    GenerationValidationError,
    validate_expected_row_count,
    validate_required_values,
    validate_unique_values,
)


MERGE_COUNT = 25

MERGE_READY_COLUMNS = (
    "MergeScenarioCode",
    "SurvivingPatientId",
    "SupersededPatientId",
    "SurvivingHospitalNumber",
    "SupersededHospitalNumber",
    "PlannedMergeReasonCode",
    "PlannedSourceMessageControlId",
    "PlannedSourceSystemCode",
    "Status",
)

MERGE_BASE_DATETIME = datetime(
    2026,
    7,
    20,
    9,
    0,
    0,
)

MERGE_CREATED_AT = datetime(
    2026,
    7,
    26,
    9,
    30,
    0,
)


def _read_merge_ready_pairs(
    input_path: Path,
) -> list[dict[str, str]]:
    """Read and validate the merge-ready pair file."""

    if not input_path.exists():
        raise FileNotFoundError(
            f"Required merge-ready file does not exist: {input_path}"
        )

    with input_path.open(
        mode="r",
        encoding="utf-8",
        newline="",
    ) as input_file:
        reader = csv.DictReader(input_file)

        actual_columns = tuple(reader.fieldnames or ())

        if actual_columns != MERGE_READY_COLUMNS:
            raise ValueError(
                "merge_ready_pairs.csv columns do not match the expected "
                f"schema.\nExpected: {MERGE_READY_COLUMNS}\n"
                f"Actual:   {actual_columns}"
            )

        rows = [
            dict(row)
            for row in reader
        ]

    if not rows:
        raise ValueError(
            "merge_ready_pairs.csv contains no data rows."
        )

    return rows


def _generate_merge_rows(
    merge_ready_pairs: list[dict[str, str]],
) -> list[dict[str, Any]]:
    """Convert merge-ready pairs into source PAS merge events."""

    merge_rows: list[dict[str, Any]] = []

    for index, pair in enumerate(
        merge_ready_pairs,
        start=1,
    ):
        merge_datetime = MERGE_BASE_DATETIME + timedelta(
            hours=index - 1
        )

        merge_rows.append(
            {
                "PatientMergeId": index,
                "SurvivingPatientId": int(
                    pair["SurvivingPatientId"]
                ),
                "SupersededPatientId": int(
                    pair["SupersededPatientId"]
                ),
                "SurvivingIdentifierValue": (
                    pair["SurvivingHospitalNumber"]
                ),
                "SupersededIdentifierValue": (
                    pair["SupersededHospitalNumber"]
                ),
                "MergeDateTime": merge_datetime.isoformat(
                    timespec="seconds"
                ),
                "MergeReasonCode": (
                    pair["PlannedMergeReasonCode"]
                ),
                "MergeReasonDescription": (
                    "Synthetic duplicate patient record merge"
                ),
                "SourceMessageControlId": (
                    pair["PlannedSourceMessageControlId"]
                ),
                "SourceSystemCode": (
                    pair["PlannedSourceSystemCode"]
                ),
                "CreatedAtUtc": MERGE_CREATED_AT.isoformat(
                    timespec="seconds"
                ),
                "UpdatedAtUtc": None,
            }
        )

    return merge_rows


def _validate_merge_rows(
    rows: list[dict[str, Any]],
) -> None:
    """Validate generated patient-merge events."""

    validate_expected_row_count(
        dataset_name="patient_merge",
        rows=rows,
        expected_count=MERGE_COUNT,
    )

    validate_unique_values(
        dataset_name="patient_merge",
        rows=rows,
        key_name="PatientMergeId",
    )

    validate_unique_values(
        dataset_name="patient_merge",
        rows=rows,
        key_name="SourceMessageControlId",
    )

    validate_required_values(
        dataset_name="patient_merge",
        rows=rows,
        required_keys=[
            "PatientMergeId",
            "SurvivingPatientId",
            "SupersededPatientId",
            "SurvivingIdentifierValue",
            "SupersededIdentifierValue",
            "MergeDateTime",
            "MergeReasonCode",
            "SourceMessageControlId",
            "SourceSystemCode",
            "CreatedAtUtc",
        ],
    )

    patient_ids: list[int] = []

    for row in rows:
        surviving_patient_id = int(
            row["SurvivingPatientId"]
        )
        superseded_patient_id = int(
            row["SupersededPatientId"]
        )

        if surviving_patient_id == superseded_patient_id:
            raise GenerationValidationError(
                f"PatientMergeId {row['PatientMergeId']} uses the same "
                "patient as both survivor and superseded record."
            )

        if (
            row["SurvivingIdentifierValue"]
            == row["SupersededIdentifierValue"]
        ):
            raise GenerationValidationError(
                f"PatientMergeId {row['PatientMergeId']} uses the same "
                "identifier for both merge sides."
            )

        patient_ids.extend(
            [
                surviving_patient_id,
                superseded_patient_id,
            ]
        )

    if len(patient_ids) != len(set(patient_ids)):
        raise GenerationValidationError(
            "A patient appears in more than one generated merge event."
        )


def generate_patient_merge_data(
    config: GeneratorConfig,
) -> list[dict[str, Any]]:
    """Generate and validate deterministic patient-merge events."""

    merge_ready_pairs = _read_merge_ready_pairs(
        input_path=(
            config.pas_output_directory
            / "merge_ready_pairs.csv"
        )
    )

    merge_rows = _generate_merge_rows(
        merge_ready_pairs=merge_ready_pairs,
    )

    _validate_merge_rows(
        rows=merge_rows,
    )

    return merge_rows