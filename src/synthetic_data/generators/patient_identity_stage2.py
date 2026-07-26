"""Generate deterministic Stage 2 patient-identity complexity for Aegis."""

from __future__ import annotations

import csv
from datetime import date, datetime
from pathlib import Path
from random import Random
from typing import Any

from synthetic_data.config import GeneratorConfig
from synthetic_data.validation.generation_validation import (
    GenerationValidationError,
    validate_expected_row_count,
    validate_required_values,
    validate_unique_values,
)


HISTORIC_IDENTIFIER_COUNT = 150
DUPLICATE_IDENTIFIER_SCENARIO_COUNT = 10
MERGE_READY_PAIR_COUNT = 25

HISTORIC_EFFECTIVE_FROM = date(2010, 1, 1)
HISTORIC_EFFECTIVE_TO = date(2014, 12, 31)

STAGE2_CREATED_AT = datetime(
    2026,
    7,
    25,
    15,
    30,
    0,
)


PATIENT_COLUMNS = (
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
)


PATIENT_IDENTIFIER_COLUMNS = (
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


def _read_csv(
    input_path: Path,
    expected_columns: tuple[str, ...],
) -> list[dict[str, Any]]:
    """Read a generated CSV and validate its exact column order."""

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

        if actual_columns != expected_columns:
            raise ValueError(
                f"{input_path.name} columns do not match the expected schema.\n"
                f"Expected: {expected_columns}\n"
                f"Actual:   {actual_columns}"
            )

        return [
            dict(row)
            for row in reader
        ]


def _next_identifier_id(
    existing_identifiers: list[dict[str, Any]],
) -> int:
    """Return the next available PatientIdentifierId."""

    return (
        max(
            int(identifier["PatientIdentifierId"])
            for identifier in existing_identifiers
        )
        + 1
    )


def _select_distinct_patient_ids(
    random_generator: Random,
    patient_ids: list[int],
    required_count: int,
) -> list[int]:
    """Select a deterministic set of distinct patients."""

    if required_count > len(patient_ids):
        raise ValueError(
            f"Cannot select {required_count} patients from "
            f"a population of {len(patient_ids)}."
        )

    return random_generator.sample(
        population=patient_ids,
        k=required_count,
    )


def _generate_historic_identifiers(
    selected_patient_ids: list[int],
    first_identifier_id: int,
) -> list[dict[str, Any]]:
    """Generate one historic hospital identifier for selected patients."""

    rows: list[dict[str, Any]] = []

    for offset, patient_id in enumerate(selected_patient_ids):
        identifier_id = first_identifier_id + offset

        rows.append(
            {
                "PatientIdentifierId": identifier_id,
                "PatientId": patient_id,
                "IdentifierValue": f"OLD{patient_id:07d}",
                "IdentifierTypeCode": "HOSPITAL_NUMBER",
                "AssigningAuthority": "AEGIS_LEGACY_PAS",
                "EffectiveFromDate": HISTORIC_EFFECTIVE_FROM.isoformat(),
                "EffectiveToDate": HISTORIC_EFFECTIVE_TO.isoformat(),
                "IsCurrent": 0,
                "CreatedAtUtc": STAGE2_CREATED_AT.isoformat(
                    timespec="seconds"
                ),
                "UpdatedAtUtc": None,
            }
        )

    return rows


def _generate_duplicate_identifier_scenarios(
    selected_patient_ids: list[int],
    first_identifier_id: int,
) -> tuple[
    list[dict[str, Any]],
    list[dict[str, Any]],
]:
    """
    Generate duplicate hospital-identifier assignments.

    Each scenario assigns the same synthetic identifier value to two different
    patients. These are deliberate source defects for later SSIS validation.
    """

    expected_patient_count = DUPLICATE_IDENTIFIER_SCENARIO_COUNT * 2

    if len(selected_patient_ids) != expected_patient_count:
        raise ValueError(
            f"Duplicate scenarios require {expected_patient_count} patients."
        )

    identifier_rows: list[dict[str, Any]] = []
    manifest_rows: list[dict[str, Any]] = []

    next_identifier_id = first_identifier_id

    for scenario_index in range(
        DUPLICATE_IDENTIFIER_SCENARIO_COUNT
    ):
        first_patient_id = selected_patient_ids[scenario_index * 2]
        second_patient_id = selected_patient_ids[
            (scenario_index * 2) + 1
        ]

        scenario_code = f"DQ-ID-{scenario_index + 1:03d}"
        duplicate_value = f"DUP{scenario_index + 1:07d}"

        for patient_id in (
            first_patient_id,
            second_patient_id,
        ):
            identifier_rows.append(
                {
                    "PatientIdentifierId": next_identifier_id,
                    "PatientId": patient_id,
                    "IdentifierValue": duplicate_value,
                    "IdentifierTypeCode": "HOSPITAL_NUMBER",
                    "AssigningAuthority": "AEGIS_LEGACY_PAS",
                    "EffectiveFromDate": "2025-01-01",
                    "EffectiveToDate": None,
                    "IsCurrent": 1,
                    "CreatedAtUtc": STAGE2_CREATED_AT.isoformat(
                        timespec="seconds"
                    ),
                    "UpdatedAtUtc": None,
                }
            )

            next_identifier_id += 1

        manifest_rows.append(
            {
                "ScenarioCode": scenario_code,
                "Domain": "PATIENT_IDENTIFIER",
                "Description": (
                    f"Hospital identifier {duplicate_value} is assigned "
                    f"to patients {first_patient_id} and {second_patient_id}."
                ),
                "ExpectedOutcome": "QUARANTINE",
                "ExpectedCount": 2,
                "SourceObject": "pas.PatientIdentifier",
                "ValidationRule": (
                    "Reject duplicate current hospital identifier values "
                    "assigned to multiple patients."
                ),
                "IdentifierValue": duplicate_value,
                "FirstPatientId": first_patient_id,
                "SecondPatientId": second_patient_id,
            }
        )

    return identifier_rows, manifest_rows


def _generate_merge_ready_pairs(
    selected_patient_ids: list[int],
    patient_lookup: dict[int, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Create deterministic surviving and superseded patient pairs."""

    expected_patient_count = MERGE_READY_PAIR_COUNT * 2

    if len(selected_patient_ids) != expected_patient_count:
        raise ValueError(
            f"Merge-ready pairs require {expected_patient_count} patients."
        )

    rows: list[dict[str, Any]] = []

    for pair_index in range(MERGE_READY_PAIR_COUNT):
        surviving_patient_id = selected_patient_ids[pair_index * 2]
        superseded_patient_id = selected_patient_ids[
            (pair_index * 2) + 1
        ]

        surviving_patient = patient_lookup[surviving_patient_id]
        superseded_patient = patient_lookup[superseded_patient_id]

        rows.append(
            {
                "MergeScenarioCode": f"MERGE-{pair_index + 1:03d}",
                "SurvivingPatientId": surviving_patient_id,
                "SupersededPatientId": superseded_patient_id,
                "SurvivingHospitalNumber": (
                    surviving_patient["HospitalNumber"]
                ),
                "SupersededHospitalNumber": (
                    superseded_patient["HospitalNumber"]
                ),
                "PlannedMergeReasonCode": "DUPLICATE_RECORD",
                "PlannedSourceMessageControlId": (
                    f"AEGIS-ADT-A40-{pair_index + 1:06d}"
                ),
                "PlannedSourceSystemCode": "AEGIS_LEGACY_PAS",
                "Status": "READY_FOR_MERGE_EVENT",
            }
        )

    return rows


def _validate_stage2_identifiers(
    baseline_identifiers: list[dict[str, Any]],
    combined_identifiers: list[dict[str, Any]],
    historic_identifiers: list[dict[str, Any]],
    duplicate_identifiers: list[dict[str, Any]],
) -> None:
    """Validate Stage 2 identifier counts and intentional complexity."""

    expected_total = (
        len(baseline_identifiers)
        + HISTORIC_IDENTIFIER_COUNT
        + (DUPLICATE_IDENTIFIER_SCENARIO_COUNT * 2)
    )

    validate_expected_row_count(
        dataset_name="patient_identifier_stage2",
        rows=combined_identifiers,
        expected_count=expected_total,
    )

    validate_expected_row_count(
        dataset_name="historic_patient_identifier",
        rows=historic_identifiers,
        expected_count=HISTORIC_IDENTIFIER_COUNT,
    )

    validate_expected_row_count(
        dataset_name="duplicate_patient_identifier",
        rows=duplicate_identifiers,
        expected_count=(
            DUPLICATE_IDENTIFIER_SCENARIO_COUNT * 2
        ),
    )

    validate_unique_values(
        dataset_name="patient_identifier_stage2",
        rows=combined_identifiers,
        key_name="PatientIdentifierId",
    )

    validate_required_values(
        dataset_name="patient_identifier_stage2",
        rows=combined_identifiers,
        required_keys=[
            "PatientIdentifierId",
            "PatientId",
            "IdentifierValue",
            "IdentifierTypeCode",
            "IsCurrent",
            "CreatedAtUtc",
        ],
    )

    invalid_historic_rows = [
        int(identifier["PatientIdentifierId"])
        for identifier in historic_identifiers
        if int(identifier["IsCurrent"]) != 0
        or not identifier["EffectiveToDate"]
    ]

    if invalid_historic_rows:
        raise GenerationValidationError(
            "Historic identifiers are not correctly closed: "
            + ", ".join(
                str(identifier_id)
                for identifier_id in invalid_historic_rows
            )
        )

    duplicate_groups: dict[str, set[int]] = {}

    for identifier in duplicate_identifiers:
        duplicate_groups.setdefault(
            str(identifier["IdentifierValue"]),
            set(),
        ).add(int(identifier["PatientId"]))

    invalid_duplicate_values = [
        identifier_value
        for identifier_value, patient_ids in duplicate_groups.items()
        if len(patient_ids) != 2
    ]

    if invalid_duplicate_values:
        raise GenerationValidationError(
            "Duplicate scenarios do not each reference exactly two patients: "
            + ", ".join(invalid_duplicate_values)
        )


def _validate_merge_pairs(
    merge_pairs: list[dict[str, Any]],
) -> None:
    """Validate that merge-ready pairs are distinct and non-overlapping."""

    validate_expected_row_count(
        dataset_name="merge_ready_pair",
        rows=merge_pairs,
        expected_count=MERGE_READY_PAIR_COUNT,
    )

    validate_unique_values(
        dataset_name="merge_ready_pair",
        rows=merge_pairs,
        key_name="MergeScenarioCode",
    )

    selected_patient_ids: list[int] = []

    for pair in merge_pairs:
        surviving_patient_id = int(pair["SurvivingPatientId"])
        superseded_patient_id = int(pair["SupersededPatientId"])

        if surviving_patient_id == superseded_patient_id:
            raise GenerationValidationError(
                f"{pair['MergeScenarioCode']} uses the same patient "
                "as survivor and superseded record."
            )

        selected_patient_ids.extend(
            [
                surviving_patient_id,
                superseded_patient_id,
            ]
        )

    if len(selected_patient_ids) != len(set(selected_patient_ids)):
        raise GenerationValidationError(
            "A patient appears in more than one merge-ready pair."
        )


def generate_patient_identity_stage2(
    config: GeneratorConfig,
    random_generator: Random,
) -> dict[str, list[dict[str, Any]]]:
    """Generate Stage 2 patient-identity datasets."""

    patients = _read_csv(
        input_path=config.pas_output_directory / "patient.csv",
        expected_columns=PATIENT_COLUMNS,
    )

    baseline_identifiers = _read_csv(
        input_path=(
            config.pas_output_directory
            / "patient_identifier.csv"
        ),
        expected_columns=PATIENT_IDENTIFIER_COLUMNS,
    )

    patient_lookup = {
        int(patient["PatientId"]): patient
        for patient in patients
    }

    all_patient_ids = sorted(patient_lookup)

    historic_patient_ids = _select_distinct_patient_ids(
        random_generator=random_generator,
        patient_ids=all_patient_ids,
        required_count=HISTORIC_IDENTIFIER_COUNT,
    )

    remaining_after_historic = [
        patient_id
        for patient_id in all_patient_ids
        if patient_id not in set(historic_patient_ids)
    ]

    duplicate_patient_ids = _select_distinct_patient_ids(
        random_generator=random_generator,
        patient_ids=remaining_after_historic,
        required_count=(
            DUPLICATE_IDENTIFIER_SCENARIO_COUNT * 2
        ),
    )

    excluded_ids = set(
        historic_patient_ids + duplicate_patient_ids
    )

    merge_candidate_population = [
        patient_id
        for patient_id in all_patient_ids
        if patient_id not in excluded_ids
    ]

    merge_patient_ids = _select_distinct_patient_ids(
        random_generator=random_generator,
        patient_ids=merge_candidate_population,
        required_count=(MERGE_READY_PAIR_COUNT * 2),
    )

    next_identifier_id = _next_identifier_id(
        existing_identifiers=baseline_identifiers
    )

    historic_identifiers = _generate_historic_identifiers(
        selected_patient_ids=historic_patient_ids,
        first_identifier_id=next_identifier_id,
    )

    next_identifier_id += len(historic_identifiers)

    (
        duplicate_identifiers,
        defect_manifest,
    ) = _generate_duplicate_identifier_scenarios(
        selected_patient_ids=duplicate_patient_ids,
        first_identifier_id=next_identifier_id,
    )

    merge_ready_pairs = _generate_merge_ready_pairs(
        selected_patient_ids=merge_patient_ids,
        patient_lookup=patient_lookup,
    )

    combined_identifiers = (
        baseline_identifiers
        + historic_identifiers
        + duplicate_identifiers
    )

    _validate_stage2_identifiers(
        baseline_identifiers=baseline_identifiers,
        combined_identifiers=combined_identifiers,
        historic_identifiers=historic_identifiers,
        duplicate_identifiers=duplicate_identifiers,
    )

    _validate_merge_pairs(
        merge_pairs=merge_ready_pairs,
    )

    return {
        "patient_identifier_stage2": combined_identifiers,
        "historic_patient_identifier": historic_identifiers,
        "duplicate_patient_identifier": duplicate_identifiers,
        "identity_defect_manifest": defect_manifest,
        "merge_ready_pair": merge_ready_pairs,
    }