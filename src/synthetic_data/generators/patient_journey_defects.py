"""Generate controlled invalid PAS journey records for SSIS testing."""

from __future__ import annotations

import csv
from copy import deepcopy
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from synthetic_data.config import GeneratorConfig
from synthetic_data.validation.generation_validation import (
    GenerationValidationError,
    validate_expected_row_count,
    validate_unique_values,
)


ADMISSION_COLUMNS = (
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
)

CONSULTANT_EPISODE_COLUMNS = (
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
)

DIAGNOSIS_COLUMNS = (
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
)

PROCEDURE_COLUMNS = (
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
)

WARD_STAY_COLUMNS = (
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
)


def _read_csv(
    input_path: Path,
    expected_columns: tuple[str, ...],
) -> list[dict[str, str]]:
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

        rows = [dict(row) for row in reader]

    if not rows:
        raise ValueError(
            f"{input_path.name} contains no data rows."
        )

    return rows


def _load_valid_inputs(
    config: GeneratorConfig,
) -> dict[str, list[dict[str, str]]]:
    """Load the valid journey baseline used to derive controlled defects."""

    return {
        "admission": _read_csv(
            config.pas_output_directory / "admission.csv",
            ADMISSION_COLUMNS,
        ),
        "consultant_episode": _read_csv(
            config.pas_output_directory / "consultant_episode.csv",
            CONSULTANT_EPISODE_COLUMNS,
        ),
        "diagnosis": _read_csv(
            config.pas_output_directory / "diagnosis.csv",
            DIAGNOSIS_COLUMNS,
        ),
        "procedure": _read_csv(
            config.pas_output_directory / "procedure.csv",
            PROCEDURE_COLUMNS,
        ),
        "ward_stay": _read_csv(
            config.pas_output_directory / "ward_stay.csv",
            WARD_STAY_COLUMNS,
        ),
    }


def _manifest_row(
    scenario_code: str,
    domain: str,
    description: str,
    expected_outcome: str,
    expected_count: int,
    source_object: str,
    validation_rule: str,
) -> dict[str, object]:
    """Create one defect-manifest row."""

    return {
        "ScenarioCode": scenario_code,
        "Domain": domain,
        "Description": description,
        "ExpectedOutcome": expected_outcome,
        "ExpectedCount": expected_count,
        "SourceObject": source_object,
        "ValidationRule": validation_rule,
    }


def _generate_admission_defects(
    valid_admissions: list[dict[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, object]]]:
    """Generate controlled invalid admission rows."""

    defects: list[dict[str, Any]] = []
    manifest: list[dict[str, object]] = []

    # DQ-ADM-001: discharge before admission.
    row = deepcopy(valid_admissions[10])
    admission_start = datetime.fromisoformat(
        row["AdmissionDateTime"]
    )
    row["AdmissionId"] = "900001"
    row["AdmissionNumber"] = "DEFADM000001"
    row["PatientPathwayId"] = "DEFPWAY000001"
    row["DischargeDateTime"] = (
        admission_start - timedelta(hours=4)
    ).isoformat(timespec="seconds")
    row["AdmissionStatusCode"] = "DISCHARGED"
    row["DischargeMethodCode"] = "1"
    row["DischargeDestinationCode"] = "19"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-ADM-001",
            "ADMISSION",
            "Discharge datetime occurs before admission datetime.",
            "QUARANTINE",
            1,
            "pas.Admission",
            "DischargeDateTime must be null or greater than or equal to "
            "AdmissionDateTime.",
        )
    )

    # DQ-ADM-002: open admission containing discharge details.
    row = deepcopy(valid_admissions[20])
    admission_start = datetime.fromisoformat(
        row["AdmissionDateTime"]
    )
    row["AdmissionId"] = "900002"
    row["AdmissionNumber"] = "DEFADM000002"
    row["PatientPathwayId"] = "DEFPWAY000002"
    row["AdmissionStatusCode"] = "OPEN"
    row["DischargeDateTime"] = (
        admission_start + timedelta(days=2)
    ).isoformat(timespec="seconds")
    row["DischargeMethodCode"] = "1"
    row["DischargeDestinationCode"] = "19"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-ADM-002",
            "ADMISSION",
            "Admission is marked open but contains discharge details.",
            "QUARANTINE",
            1,
            "pas.Admission",
            "OPEN admissions must not contain discharge datetime, method "
            "or destination.",
        )
    )

    # DQ-ADM-003: discharged admission without discharge details.
    row = deepcopy(valid_admissions[30])
    row["AdmissionId"] = "900003"
    row["AdmissionNumber"] = "DEFADM000003"
    row["PatientPathwayId"] = "DEFPWAY000003"
    row["AdmissionStatusCode"] = "DISCHARGED"
    row["DischargeDateTime"] = ""
    row["DischargeMethodCode"] = ""
    row["DischargeDestinationCode"] = ""
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-ADM-003",
            "ADMISSION",
            "Admission is marked discharged but has no discharge details.",
            "QUARANTINE",
            1,
            "pas.Admission",
            "DISCHARGED admissions require discharge datetime and method.",
        )
    )

    # DQ-ADM-004: unknown patient.
    row = deepcopy(valid_admissions[40])
    row["AdmissionId"] = "900004"
    row["AdmissionNumber"] = "DEFADM000004"
    row["PatientPathwayId"] = "DEFPWAY000004"
    row["PatientId"] = "999999"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-ADM-004",
            "ADMISSION",
            "Admission references a patient not present in the source "
            "patient extract.",
            "QUARANTINE",
            1,
            "pas.Admission",
            "PatientId must resolve to the patient identity domain.",
        )
    )

    # DQ-ADM-005: unknown organisation and site.
    row = deepcopy(valid_admissions[50])
    row["AdmissionId"] = "900005"
    row["AdmissionNumber"] = "DEFADM000005"
    row["PatientPathwayId"] = "DEFPWAY000005"
    row["OrganisationId"] = "9999"
    row["SiteId"] = "9999"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-ADM-005",
            "ADMISSION",
            "Admission references unknown organisation and site values.",
            "QUARANTINE",
            1,
            "pas.Admission",
            "OrganisationId and SiteId must resolve to governed reference "
            "data.",
        )
    )

    return defects, manifest


def _generate_episode_defects(
    valid_admissions: list[dict[str, str]],
    valid_episodes: list[dict[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, object]]]:
    """Generate controlled invalid consultant episode rows."""

    defects: list[dict[str, Any]] = []
    manifest: list[dict[str, object]] = []

    admission_lookup = {
        row["AdmissionId"]: row
        for row in valid_admissions
    }

    # DQ-EPI-001: episode starts before admission.
    row = deepcopy(valid_episodes[10])
    admission = admission_lookup[row["AdmissionId"]]
    admission_start = datetime.fromisoformat(
        admission["AdmissionDateTime"]
    )

    row["ConsultantEpisodeId"] = "910001"
    row["EpisodeNumber"] = "DEFEPI000001"
    row["EpisodeStartDateTime"] = (
        admission_start - timedelta(hours=6)
    ).isoformat(timespec="seconds")
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-EPI-001",
            "CONSULTANT_EPISODE",
            "Consultant episode begins before its admission.",
            "QUARANTINE",
            1,
            "pas.ConsultantEpisode",
            "EpisodeStartDateTime must be on or after AdmissionDateTime.",
        )
    )

    # DQ-EPI-002: episode ends after discharge.
    row = deepcopy(
        next(
            episode
            for episode in valid_episodes
            if admission_lookup[
                episode["AdmissionId"]
            ]["DischargeDateTime"]
        )
    )
    admission = admission_lookup[row["AdmissionId"]]
    discharge_datetime = datetime.fromisoformat(
        admission["DischargeDateTime"]
    )

    row["ConsultantEpisodeId"] = "910002"
    row["EpisodeNumber"] = "DEFEPI000002"
    row["EpisodeEndDateTime"] = (
        discharge_datetime + timedelta(hours=8)
    ).isoformat(timespec="seconds")
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-EPI-002",
            "CONSULTANT_EPISODE",
            "Consultant episode ends after discharge.",
            "QUARANTINE",
            1,
            "pas.ConsultantEpisode",
            "EpisodeEndDateTime must not exceed DischargeDateTime.",
        )
    )

    # DQ-EPI-003: unknown admission.
    row = deepcopy(valid_episodes[30])
    row["ConsultantEpisodeId"] = "910003"
    row["EpisodeNumber"] = "DEFEPI000003"
    row["AdmissionId"] = "999999"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-EPI-003",
            "CONSULTANT_EPISODE",
            "Consultant episode references an unknown admission.",
            "QUARANTINE",
            1,
            "pas.ConsultantEpisode",
            "AdmissionId must resolve before consultant episode loading.",
        )
    )

    # DQ-EPI-004: sequence gap.
    row = deepcopy(valid_episodes[40])
    row["ConsultantEpisodeId"] = "910004"
    row["EpisodeNumber"] = "DEFEPI000004"
    row["EpisodeSequence"] = "9"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-EPI-004",
            "CONSULTANT_EPISODE",
            "Episode sequence is not contiguous within the admission.",
            "QUARANTINE",
            1,
            "pas.ConsultantEpisode",
            "EpisodeSequence must begin at 1 and remain contiguous per "
            "admission.",
        )
    )

    return defects, manifest


def _generate_diagnosis_defects(
    valid_episodes: list[dict[str, str]],
    valid_diagnoses: list[dict[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, object]]]:
    """Generate controlled invalid diagnosis rows."""

    defects: list[dict[str, Any]] = []
    manifest: list[dict[str, object]] = []

    episode_lookup = {
        row["ConsultantEpisodeId"]: row
        for row in valid_episodes
    }

    # DQ-DIA-001: unknown episode.
    row = deepcopy(valid_diagnoses[10])
    row["DiagnosisId"] = "920001"
    row["SourceDiagnosisId"] = "DEF-DIAG-000001"
    row["ConsultantEpisodeId"] = "999999"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-DIA-001",
            "DIAGNOSIS",
            "Diagnosis references an unknown consultant episode.",
            "QUARANTINE",
            1,
            "pas.Diagnosis",
            "ConsultantEpisodeId must resolve before diagnosis loading.",
        )
    )

    # DQ-DIA-002: diagnosis outside episode.
    row = deepcopy(valid_diagnoses[20])
    episode = episode_lookup[row["ConsultantEpisodeId"]]
    episode_start = datetime.fromisoformat(
        episode["EpisodeStartDateTime"]
    )

    row["DiagnosisId"] = "920002"
    row["SourceDiagnosisId"] = "DEF-DIAG-000002"
    row["DiagnosisDate"] = (
        episode_start.date() - timedelta(days=10)
    ).isoformat()
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-DIA-002",
            "DIAGNOSIS",
            "Diagnosis date occurs outside its consultant episode.",
            "QUARANTINE",
            1,
            "pas.Diagnosis",
            "DiagnosisDate must fall within the consultant episode.",
        )
    )

    # DQ-DIA-003: duplicate primary diagnosis.
    source_rows = [
        deepcopy(row)
        for row in valid_diagnoses
        if row["ConsultantEpisodeId"]
        == valid_diagnoses[30]["ConsultantEpisodeId"]
    ][:2]

    if len(source_rows) < 2:
        raise GenerationValidationError(
            "Unable to find an episode with two diagnoses for "
            "DQ-DIA-003."
        )

    for index, row in enumerate(source_rows, start=1):
        row["DiagnosisId"] = str(920002 + index)
        row["SourceDiagnosisId"] = f"DEF-DIAG-00000{2 + index}"
        row["IsPrimaryDiagnosis"] = "1"
        defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-DIA-003",
            "DIAGNOSIS",
            "Two diagnoses are marked primary for one consultant episode.",
            "QUARANTINE",
            2,
            "pas.Diagnosis",
            "Each consultant episode must contain exactly one primary "
            "diagnosis.",
        )
    )

    return defects, manifest


def _generate_procedure_defects(
    valid_episodes: list[dict[str, str]],
    valid_procedures: list[dict[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, object]]]:
    """Generate controlled invalid procedure rows."""

    defects: list[dict[str, Any]] = []
    manifest: list[dict[str, object]] = []

    episode_lookup = {
        row["ConsultantEpisodeId"]: row
        for row in valid_episodes
    }

    # DQ-PRO-001: procedure outside episode.
    row = deepcopy(valid_procedures[10])
    episode = episode_lookup[row["ConsultantEpisodeId"]]
    episode_start = datetime.fromisoformat(
        episode["EpisodeStartDateTime"]
    )

    row["ProcedureId"] = "930001"
    row["SourceProcedureId"] = "DEF-PROC-000001"
    row["ProcedureDateTime"] = (
        episode_start - timedelta(days=2)
    ).isoformat(timespec="seconds")
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-PRO-001",
            "PROCEDURE",
            "Procedure datetime occurs outside its consultant episode.",
            "QUARANTINE",
            1,
            "pas.Procedure",
            "ProcedureDateTime must fall within the consultant episode.",
        )
    )

    # DQ-PRO-002: unknown consultant.
    row = deepcopy(valid_procedures[20])
    row["ProcedureId"] = "930002"
    row["SourceProcedureId"] = "DEF-PROC-000002"
    row["ConsultantId"] = "999999"
    defects.append(row)

    manifest.append(
        _manifest_row(
            "DQ-PRO-002",
            "PROCEDURE",
            "Procedure references an unknown consultant.",
            "QUARANTINE",
            1,
            "pas.Procedure",
            "ConsultantId must resolve to governed consultant reference "
            "data.",
        )
    )

    return defects, manifest


def _generate_ward_stay_defects(
    valid_ward_stays: list[dict[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, object]]]:
    """Generate overlapping ward-stay records."""

    stays_by_admission: dict[str, list[dict[str, str]]] = {}

    for stay in valid_ward_stays:
        stays_by_admission.setdefault(
            stay["AdmissionId"],
            [],
        ).append(stay)

    source_stays = next(
        stays
        for stays in stays_by_admission.values()
        if len(stays) >= 2
    )

    source_stays = sorted(
        source_stays,
        key=lambda row: int(row["WardStaySequence"]),
    )[:2]

    first_stay = deepcopy(source_stays[0])
    second_stay = deepcopy(source_stays[1])

    first_start = datetime.fromisoformat(
        first_stay["WardStartDateTime"]
    )
    first_end = datetime.fromisoformat(
        first_stay["WardEndDateTime"]
    )

    overlap_start = first_start + (
        (first_end - first_start) / 2
    )

    first_stay["WardStayId"] = "940001"
    first_stay["SourceWardStayId"] = "DEF-WARD-000001"

    second_stay["WardStayId"] = "940002"
    second_stay["SourceWardStayId"] = "DEF-WARD-000002"
    second_stay["WardStartDateTime"] = overlap_start.isoformat(
        timespec="seconds"
    )

    defects = [
        first_stay,
        second_stay,
    ]

    manifest = [
        _manifest_row(
            "DQ-WARD-001",
            "WARD_STAY",
            "Two ward stays overlap within the same admission.",
            "QUARANTINE",
            2,
            "pas.WardStay",
            "Ward movements must be contiguous and non-overlapping within "
            "an admission.",
        )
    ]

    return defects, manifest


def _validate_outputs(
    datasets: dict[str, list[dict[str, Any]]],
    manifest: list[dict[str, object]],
) -> None:
    """Validate expected controlled-defect totals."""

    validate_expected_row_count(
        "admission_defect",
        datasets["admission_defect"],
        5,
    )
    validate_expected_row_count(
        "consultant_episode_defect",
        datasets["consultant_episode_defect"],
        4,
    )
    validate_expected_row_count(
        "diagnosis_defect",
        datasets["diagnosis_defect"],
        4,
    )
    validate_expected_row_count(
        "procedure_defect",
        datasets["procedure_defect"],
        2,
    )
    validate_expected_row_count(
        "ward_stay_defect",
        datasets["ward_stay_defect"],
        2,
    )
    validate_expected_row_count(
        "journey_defect_manifest",
        manifest,
        15,
    )

    validate_unique_values(
        "journey_defect_manifest",
        manifest,
        "ScenarioCode",
    )


def generate_patient_journey_defects(
    config: GeneratorConfig,
) -> dict[str, list[dict[str, Any]]]:
    """Generate the complete controlled PAS journey defect pack."""

    valid_inputs = _load_valid_inputs(config)

    admission_defects, admission_manifest = (
        _generate_admission_defects(
            valid_admissions=valid_inputs["admission"],
        )
    )

    episode_defects, episode_manifest = (
        _generate_episode_defects(
            valid_admissions=valid_inputs["admission"],
            valid_episodes=valid_inputs["consultant_episode"],
        )
    )

    diagnosis_defects, diagnosis_manifest = (
        _generate_diagnosis_defects(
            valid_episodes=valid_inputs["consultant_episode"],
            valid_diagnoses=valid_inputs["diagnosis"],
        )
    )

    procedure_defects, procedure_manifest = (
        _generate_procedure_defects(
            valid_episodes=valid_inputs["consultant_episode"],
            valid_procedures=valid_inputs["procedure"],
        )
    )

    ward_stay_defects, ward_manifest = (
        _generate_ward_stay_defects(
            valid_ward_stays=valid_inputs["ward_stay"],
        )
    )

    manifest = (
        admission_manifest
        + episode_manifest
        + diagnosis_manifest
        + procedure_manifest
        + ward_manifest
    )

    datasets = {
        "admission_defect": admission_defects,
        "consultant_episode_defect": episode_defects,
        "diagnosis_defect": diagnosis_defects,
        "procedure_defect": procedure_defects,
        "ward_stay_defect": ward_stay_defects,
        "journey_defect_manifest": manifest,
    }

    _validate_outputs(
        datasets=datasets,
        manifest=manifest,
    )

    return datasets