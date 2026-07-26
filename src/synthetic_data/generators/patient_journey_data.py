"""Generate deterministic valid admitted-patient journeys for Aegis."""

from __future__ import annotations

import csv
from datetime import date, datetime, time, timedelta
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


ADMISSION_COUNT = 1_600
OPEN_ADMISSION_PERCENTAGE = 12

GENERATION_DATETIME = datetime(2026, 7, 26, 10, 0, 0)
EARLIEST_ADMISSION_DATE = date(2023, 1, 1)
LATEST_CLOSED_ADMISSION_DATE = date(2026, 7, 10)
EARLIEST_OPEN_ADMISSION_DATE = date(2026, 7, 12)
LATEST_OPEN_ADMISSION_DATE = date(2026, 7, 25)


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


PATIENT_MERGE_COLUMNS = (
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


ORGANISATION_COLUMNS = (
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
)


SITE_COLUMNS = (
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
)


SPECIALTY_COLUMNS = (
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
)


CONSULTANT_COLUMNS = (
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
)


WARD_COLUMNS = (
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
)


ADMISSION_METHOD_CODES = (
    "11",
    "12",
    "13",
    "21",
    "22",
    "23",
    "24",
    "28",
)

ADMISSION_SOURCE_CODES = (
    "19",
    "29",
    "49",
    "51",
    "52",
)

PATIENT_CLASSIFICATION_CODES = (
    "1",
    "1",
    "1",
    "2",
    "2",
    "3",
)

INTENDED_MANAGEMENT_CODES = (
    "1",
    "2",
    "3",
    "8",
)

DISCHARGE_METHOD_CODES = (
    "1",
    "1",
    "1",
    "2",
    "4",
)

DISCHARGE_DESTINATION_CODES = (
    "19",
    "19",
    "19",
    "29",
    "49",
    "51",
)

ADMINISTRATIVE_CATEGORY_CODES = (
    "01",
    "01",
    "01",
    "02",
)

EPISODE_TYPE_CODES = (
    "CONSULTANT",
    "CONSULTANT",
    "CONSULTANT",
    "SHARED_CARE",
)

DIAGNOSIS_DEFINITIONS = (
    ("AEG-D001", "Synthetic respiratory condition"),
    ("AEG-D002", "Synthetic cardiac condition"),
    ("AEG-D003", "Synthetic gastrointestinal condition"),
    ("AEG-D004", "Synthetic orthopaedic condition"),
    ("AEG-D005", "Synthetic neurological condition"),
    ("AEG-D006", "Synthetic infectious condition"),
    ("AEG-D007", "Synthetic renal condition"),
    ("AEG-D008", "Synthetic endocrine condition"),
    ("AEG-D009", "Synthetic injury"),
    ("AEG-D010", "Synthetic observation finding"),
    ("AEG-D011", "Synthetic postoperative condition"),
    ("AEG-D012", "Synthetic chronic condition"),
)

PROCEDURE_DEFINITIONS = (
    ("AEG-P001", "Synthetic diagnostic procedure"),
    ("AEG-P002", "Synthetic therapeutic procedure"),
    ("AEG-P003", "Synthetic imaging procedure"),
    ("AEG-P004", "Synthetic surgical procedure"),
    ("AEG-P005", "Synthetic endoscopic procedure"),
    ("AEG-P006", "Synthetic rehabilitation procedure"),
    ("AEG-P007", "Synthetic monitoring procedure"),
    ("AEG-P008", "Synthetic day-case procedure"),
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


def _datetime_text(value: datetime | None) -> str | None:
    """Return an ISO datetime value without timezone information."""

    if value is None:
        return None

    return value.isoformat(timespec="seconds")


def _random_datetime_between(
    random_generator: Random,
    start_datetime: datetime,
    end_datetime: datetime,
) -> datetime:
    """Return a random datetime within an inclusive interval."""

    if end_datetime < start_datetime:
        raise ValueError(
            "end_datetime must not be earlier than start_datetime."
        )

    available_seconds = int(
        (end_datetime - start_datetime).total_seconds()
    )

    return start_datetime + timedelta(
        seconds=random_generator.randint(0, available_seconds)
    )


def _random_date_between(
    random_generator: Random,
    start_date: date,
    end_date: date,
) -> date:
    """Return a random date within an inclusive interval."""

    if end_date < start_date:
        raise ValueError(
            "end_date must not be earlier than start_date."
        )

    available_days = (end_date - start_date).days

    return start_date + timedelta(
        days=random_generator.randint(0, available_days)
    )


def _partition_interval(
    start_datetime: datetime,
    end_datetime: datetime,
    part_count: int,
) -> list[tuple[datetime, datetime]]:
    """Split a datetime interval into contiguous non-empty parts."""

    if part_count < 1:
        raise ValueError("part_count must be at least 1.")

    total_seconds = max(
        int((end_datetime - start_datetime).total_seconds()),
        part_count,
    )

    base_seconds = total_seconds // part_count
    remainder = total_seconds % part_count

    intervals: list[tuple[datetime, datetime]] = []
    current_start = start_datetime

    for index in range(part_count):
        interval_seconds = base_seconds

        if index < remainder:
            interval_seconds += 1

        current_end = current_start + timedelta(
            seconds=interval_seconds
        )

        intervals.append(
            (
                current_start,
                current_end,
            )
        )

        current_start = current_end

    intervals[-1] = (
        intervals[-1][0],
        end_datetime,
    )

    return intervals


def _load_inputs(
    config: GeneratorConfig,
) -> dict[str, list[dict[str, str]]]:
    """Load all source datasets required by the journey generator."""

    return {
        "patients": _read_csv(
            config.pas_output_directory / "patient.csv",
            PATIENT_COLUMNS,
        ),
        "patient_merges": _read_csv(
            config.pas_output_directory / "patient_merge.csv",
            PATIENT_MERGE_COLUMNS,
        ),
        "organisations": _read_csv(
            config.reference_output_directory / "organisation.csv",
            ORGANISATION_COLUMNS,
        ),
        "sites": _read_csv(
            config.reference_output_directory / "site.csv",
            SITE_COLUMNS,
        ),
        "specialties": _read_csv(
            config.reference_output_directory / "specialty.csv",
            SPECIALTY_COLUMNS,
        ),
        "consultants": _read_csv(
            config.reference_output_directory / "consultant.csv",
            CONSULTANT_COLUMNS,
        ),
        "wards": _read_csv(
            config.reference_output_directory / "ward.csv",
            WARD_COLUMNS,
        ),
    }


def _eligible_patients(
    patients: list[dict[str, str]],
    patient_merges: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Exclude superseded and deceased patients from new valid activity."""

    superseded_patient_ids = {
        int(row["SupersededPatientId"])
        for row in patient_merges
    }

    eligible = [
        patient
        for patient in patients
        if int(patient["PatientId"]) not in superseded_patient_ids
        and patient["PatientStatusCode"] != "DECEASED"
        and patient["IsDeleted"] == "0"
    ]

    if not eligible:
        raise GenerationValidationError(
            "No eligible patients are available for journey generation."
        )

    return eligible


def _generate_admissions(
    random_generator: Random,
    eligible_patients: list[dict[str, str]],
    organisations: list[dict[str, str]],
    sites: list[dict[str, str]],
) -> list[dict[str, Any]]:
    """Generate valid synthetic admissions."""

    rows: list[dict[str, Any]] = []

    organisation_lookup = {
        int(row["OrganisationId"]): row
        for row in organisations
    }

    open_admission_count = round(
        ADMISSION_COUNT * OPEN_ADMISSION_PERCENTAGE / 100
    )

    for zero_based_index in range(ADMISSION_COUNT):
        admission_id = zero_based_index + 1
        is_open = admission_id <= open_admission_count

        patient = random_generator.choice(
            eligible_patients
        )

        site = random_generator.choice(sites)
        organisation_id = int(site["OrganisationId"])

        if organisation_id not in organisation_lookup:
            raise GenerationValidationError(
                f"Site {site['SiteId']} references an unknown organisation."
            )

        if is_open:
            admission_date = _random_date_between(
                random_generator,
                EARLIEST_OPEN_ADMISSION_DATE,
                LATEST_OPEN_ADMISSION_DATE,
            )
        else:
            admission_date = _random_date_between(
                random_generator,
                EARLIEST_ADMISSION_DATE,
                LATEST_CLOSED_ADMISSION_DATE,
            )

        admission_datetime = datetime.combine(
            admission_date,
            time(
                hour=random_generator.randint(0, 23),
                minute=random_generator.choice(
                    (0, 10, 15, 20, 30, 40, 45, 50)
                ),
            ),
        )

        if is_open:
            discharge_datetime = None
            discharge_method_code = None
            discharge_destination_code = None
            admission_status_code = "OPEN"
        else:
            length_of_stay_hours = random_generator.randint(
                8,
                14 * 24,
            )

            discharge_datetime = admission_datetime + timedelta(
                hours=length_of_stay_hours
            )

            discharge_method_code = random_generator.choice(
                DISCHARGE_METHOD_CODES
            )
            discharge_destination_code = random_generator.choice(
                DISCHARGE_DESTINATION_CODES
            )
            admission_status_code = "DISCHARGED"

        rows.append(
            {
                "AdmissionId": admission_id,
                "PatientId": int(patient["PatientId"]),
                "OrganisationId": organisation_id,
                "SiteId": int(site["SiteId"]),
                "AdmissionNumber": f"ADM{admission_id:08d}",
                "PatientPathwayId": f"PWAY{admission_id:08d}",
                "AdmissionDateTime": _datetime_text(
                    admission_datetime
                ),
                "DischargeDateTime": _datetime_text(
                    discharge_datetime
                ),
                "AdmissionMethodCode": random_generator.choice(
                    ADMISSION_METHOD_CODES
                ),
                "AdmissionSourceCode": random_generator.choice(
                    ADMISSION_SOURCE_CODES
                ),
                "PatientClassificationCode": random_generator.choice(
                    PATIENT_CLASSIFICATION_CODES
                ),
                "IntendedManagementCode": random_generator.choice(
                    INTENDED_MANAGEMENT_CODES
                ),
                "DischargeMethodCode": discharge_method_code,
                "DischargeDestinationCode": (
                    discharge_destination_code
                ),
                "AdministrativeCategoryCode": (
                    random_generator.choice(
                        ADMINISTRATIVE_CATEGORY_CODES
                    )
                ),
                "LegalStatusCode": None,
                "AdmissionStatusCode": admission_status_code,
                "RecordCreatedAt": _datetime_text(
                    GENERATION_DATETIME
                ),
                "RecordUpdatedAt": _datetime_text(
                    GENERATION_DATETIME
                ),
                "IsDeleted": 0,
            }
        )

    return rows


def _generate_consultant_episodes(
    random_generator: Random,
    admissions: list[dict[str, Any]],
    consultants: list[dict[str, str]],
) -> list[dict[str, Any]]:
    """Generate valid consultant episodes within admissions."""

    rows: list[dict[str, Any]] = []
    next_episode_id = 1

    for admission in admissions:
        admission_start = datetime.fromisoformat(
            str(admission["AdmissionDateTime"])
        )

        discharge_value = admission["DischargeDateTime"]

        if discharge_value is None:
            interval_end = GENERATION_DATETIME
            episode_count = random_generator.randint(1, 2)
            admission_is_open = True
        else:
            interval_end = datetime.fromisoformat(
                str(discharge_value)
            )
            episode_count = random_generator.randint(1, 3)
            admission_is_open = False

        intervals = _partition_interval(
            start_datetime=admission_start,
            end_datetime=interval_end,
            part_count=episode_count,
        )

        for sequence, interval in enumerate(
            intervals,
            start=1,
        ):
            consultant = random_generator.choice(
                consultants
            )

            episode_start, calculated_episode_end = interval

            is_final_open_episode = (
                admission_is_open
                and sequence == episode_count
            )

            episode_end = (
                None
                if is_final_open_episode
                else calculated_episode_end
            )

            episode_status_code = (
                "OPEN"
                if is_final_open_episode
                else "CLOSED"
            )

            rows.append(
                {
                    "ConsultantEpisodeId": next_episode_id,
                    "AdmissionId": int(
                        admission["AdmissionId"]
                    ),
                    "EpisodeNumber": (
                        f"EPI{next_episode_id:09d}"
                    ),
                    "EpisodeSequence": sequence,
                    "ConsultantId": int(
                        consultant["ConsultantId"]
                    ),
                    "MainSpecialtyId": int(
                        consultant["MainSpecialtyId"]
                    ),
                    "TreatmentSpecialtyId": int(
                        consultant["MainSpecialtyId"]
                    ),
                    "EpisodeStartDateTime": _datetime_text(
                        episode_start
                    ),
                    "EpisodeEndDateTime": _datetime_text(
                        episode_end
                    ),
                    "EpisodeStatusCode": episode_status_code,
                    "EpisodeTypeCode": random_generator.choice(
                        EPISODE_TYPE_CODES
                    ),
                    "PatientClassificationCode": (
                        admission["PatientClassificationCode"]
                    ),
                    "RecordCreatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "RecordUpdatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "IsDeleted": 0,
                }
            )

            next_episode_id += 1

    return rows


def _generate_diagnoses(
    random_generator: Random,
    consultant_episodes: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Generate one to four valid diagnoses for each episode."""

    rows: list[dict[str, Any]] = []
    next_diagnosis_id = 1

    for episode in consultant_episodes:
        episode_start = datetime.fromisoformat(
            str(episode["EpisodeStartDateTime"])
        )

        episode_end_value = episode["EpisodeEndDateTime"]

        episode_end = (
            datetime.fromisoformat(str(episode_end_value))
            if episode_end_value is not None
            else GENERATION_DATETIME
        )

        diagnosis_count = random_generator.randint(1, 4)

        for sequence in range(1, diagnosis_count + 1):
            code, description = random_generator.choice(
                DIAGNOSIS_DEFINITIONS
            )

            diagnosis_datetime = _random_datetime_between(
                random_generator,
                episode_start,
                episode_end,
            )

            rows.append(
                {
                    "DiagnosisId": next_diagnosis_id,
                    "ConsultantEpisodeId": int(
                        episode["ConsultantEpisodeId"]
                    ),
                    "SourceDiagnosisId": (
                        f"SRC-DIAG-{next_diagnosis_id:09d}"
                    ),
                    "DiagnosisSequence": sequence,
                    "IsPrimaryDiagnosis": (
                        1 if sequence == 1 else 0
                    ),
                    "DiagnosisCode": code,
                    "DiagnosisCodeSystem": "AEGIS_LOCAL",
                    "DiagnosisDescription": description,
                    "DiagnosisDate": (
                        diagnosis_datetime.date().isoformat()
                    ),
                    "PresentOnAdmissionCode": (
                        "Y" if sequence == 1 else "N"
                    ),
                    "LateralityCode": random_generator.choice(
                        (None, None, "L", "R", "B")
                    ),
                    "DiagnosisStatusCode": "CONFIRMED",
                    "RecordCreatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "RecordUpdatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "IsDeleted": 0,
                }
            )

            next_diagnosis_id += 1

    return rows


def _generate_procedures(
    random_generator: Random,
    consultant_episodes: list[dict[str, Any]],
    admissions_by_id: dict[int, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Generate zero to two valid procedures for each episode."""

    rows: list[dict[str, Any]] = []
    next_procedure_id = 1

    for episode in consultant_episodes:
        procedure_count = random_generator.choices(
            population=(0, 1, 2),
            weights=(45, 40, 15),
            k=1,
        )[0]

        if procedure_count == 0:
            continue

        episode_start = datetime.fromisoformat(
            str(episode["EpisodeStartDateTime"])
        )

        episode_end_value = episode["EpisodeEndDateTime"]

        episode_end = (
            datetime.fromisoformat(str(episode_end_value))
            if episode_end_value is not None
            else GENERATION_DATETIME
        )

        admission = admissions_by_id[
            int(episode["AdmissionId"])
        ]

        for sequence in range(1, procedure_count + 1):
            code, description = random_generator.choice(
                PROCEDURE_DEFINITIONS
            )

            procedure_datetime = _random_datetime_between(
                random_generator,
                episode_start,
                episode_end,
            )

            rows.append(
                {
                    "ProcedureId": next_procedure_id,
                    "ConsultantEpisodeId": int(
                        episode["ConsultantEpisodeId"]
                    ),
                    "SourceProcedureId": (
                        f"SRC-PROC-{next_procedure_id:09d}"
                    ),
                    "ProcedureSequence": sequence,
                    "IsPrimaryProcedure": (
                        1 if sequence == 1 else 0
                    ),
                    "ProcedureCode": code,
                    "ProcedureCodeSystem": "AEGIS_LOCAL",
                    "ProcedureDescription": description,
                    "ProcedureDateTime": _datetime_text(
                        procedure_datetime
                    ),
                    "ProcedureSiteCode": "AEGIS_SITE",
                    "LateralityCode": random_generator.choice(
                        (None, None, "L", "R", "B")
                    ),
                    "ProcedureStatusCode": "COMPLETED",
                    "ConsultantId": int(
                        episode["ConsultantId"]
                    ),
                    "SiteId": int(admission["SiteId"]),
                    "RecordCreatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "RecordUpdatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "IsDeleted": 0,
                }
            )

            next_procedure_id += 1

    return rows


def _generate_ward_stays(
    random_generator: Random,
    admissions: list[dict[str, Any]],
    wards: list[dict[str, str]],
) -> list[dict[str, Any]]:
    """Generate valid ward movements within each admission."""

    rows: list[dict[str, Any]] = []
    next_ward_stay_id = 1

    wards_by_site: dict[int, list[dict[str, str]]] = {}

    for ward in wards:
        wards_by_site.setdefault(
            int(ward["SiteId"]),
            [],
        ).append(ward)

    for admission in admissions:
        admission_start = datetime.fromisoformat(
            str(admission["AdmissionDateTime"])
        )

        discharge_value = admission["DischargeDateTime"]

        admission_is_open = discharge_value is None

        interval_end = (
            GENERATION_DATETIME
            if admission_is_open
            else datetime.fromisoformat(str(discharge_value))
        )

        site_id = int(admission["SiteId"])
        available_wards = wards_by_site.get(site_id, [])

        if not available_wards:
            raise GenerationValidationError(
                f"No wards exist for SiteId {site_id}."
            )

        ward_stay_count = min(
            random_generator.randint(1, 3),
            len(available_wards),
        )

        selected_wards = random_generator.sample(
            available_wards,
            k=ward_stay_count,
        )

        intervals = _partition_interval(
            start_datetime=admission_start,
            end_datetime=interval_end,
            part_count=ward_stay_count,
        )

        for sequence, (
            ward,
            interval,
        ) in enumerate(
            zip(
                selected_wards,
                intervals,
                strict=True,
            ),
            start=1,
        ):
            ward_start, calculated_ward_end = interval

            is_final_open_stay = (
                admission_is_open
                and sequence == ward_stay_count
            )

            ward_end = (
                None
                if is_final_open_stay
                else calculated_ward_end
            )

            rows.append(
                {
                    "WardStayId": next_ward_stay_id,
                    "AdmissionId": int(
                        admission["AdmissionId"]
                    ),
                    "WardId": int(ward["WardId"]),
                    "SourceWardStayId": (
                        f"SRC-WARD-{next_ward_stay_id:09d}"
                    ),
                    "WardStaySequence": sequence,
                    "WardStartDateTime": _datetime_text(
                        ward_start
                    ),
                    "WardEndDateTime": _datetime_text(
                        ward_end
                    ),
                    "AdmissionWardFlag": (
                        1 if sequence == 1 else 0
                    ),
                    "DischargeWardFlag": (
                        1
                        if (
                            not admission_is_open
                            and sequence == ward_stay_count
                        )
                        else 0
                    ),
                    "BedNumber": (
                        f"B{random_generator.randint(1, 36):02d}"
                    ),
                    "BayCode": (
                        f"BAY{random_generator.randint(1, 8):02d}"
                    ),
                    "WardStayStatusCode": (
                        "OPEN"
                        if is_final_open_stay
                        else "CLOSED"
                    ),
                    "RecordCreatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "RecordUpdatedAt": _datetime_text(
                        GENERATION_DATETIME
                    ),
                    "IsDeleted": 0,
                }
            )

            next_ward_stay_id += 1

    return rows


def _validate_admissions(
    admissions: list[dict[str, Any]],
    eligible_patient_ids: set[int],
) -> None:
    """Validate generated admissions."""

    validate_expected_row_count(
        "admission",
        admissions,
        ADMISSION_COUNT,
    )

    validate_unique_values(
        "admission",
        admissions,
        "AdmissionId",
    )

    validate_unique_values(
        "admission",
        admissions,
        "AdmissionNumber",
    )

    validate_required_values(
        "admission",
        admissions,
        [
            "AdmissionId",
            "PatientId",
            "AdmissionNumber",
            "AdmissionDateTime",
            "AdmissionStatusCode",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )

    invalid_rows: list[int] = []

    for admission in admissions:
        admission_id = int(admission["AdmissionId"])
        patient_id = int(admission["PatientId"])

        if patient_id not in eligible_patient_ids:
            invalid_rows.append(admission_id)
            continue

        admission_start = datetime.fromisoformat(
            str(admission["AdmissionDateTime"])
        )

        discharge_value = admission["DischargeDateTime"]

        if discharge_value is not None:
            discharge_datetime = datetime.fromisoformat(
                str(discharge_value)
            )

            if discharge_datetime < admission_start:
                invalid_rows.append(admission_id)

        if (
            admission["AdmissionStatusCode"] == "OPEN"
            and discharge_value is not None
        ):
            invalid_rows.append(admission_id)

        if (
            admission["AdmissionStatusCode"] == "DISCHARGED"
            and discharge_value is None
        ):
            invalid_rows.append(admission_id)

    if invalid_rows:
        raise GenerationValidationError(
            "Invalid admissions were generated: "
            + ", ".join(
                str(admission_id)
                for admission_id in invalid_rows[:20]
            )
        )


def _validate_episodes(
    admissions: list[dict[str, Any]],
    episodes: list[dict[str, Any]],
) -> None:
    """Validate consultant episodes and chronology."""

    validate_unique_values(
        "consultant_episode",
        episodes,
        "ConsultantEpisodeId",
    )

    validate_unique_values(
        "consultant_episode",
        episodes,
        "EpisodeNumber",
    )

    admission_lookup = {
        int(row["AdmissionId"]): row
        for row in admissions
    }

    sequences_by_admission: dict[int, list[int]] = {}
    invalid_episode_ids: list[int] = []

    for episode in episodes:
        episode_id = int(
            episode["ConsultantEpisodeId"]
        )
        admission_id = int(episode["AdmissionId"])
        sequence = int(episode["EpisodeSequence"])

        admission = admission_lookup.get(admission_id)

        if admission is None:
            invalid_episode_ids.append(episode_id)
            continue

        sequences_by_admission.setdefault(
            admission_id,
            [],
        ).append(sequence)

        admission_start = datetime.fromisoformat(
            str(admission["AdmissionDateTime"])
        )

        admission_end = (
            datetime.fromisoformat(
                str(admission["DischargeDateTime"])
            )
            if admission["DischargeDateTime"] is not None
            else GENERATION_DATETIME
        )

        episode_start = datetime.fromisoformat(
            str(episode["EpisodeStartDateTime"])
        )

        episode_end = (
            datetime.fromisoformat(
                str(episode["EpisodeEndDateTime"])
            )
            if episode["EpisodeEndDateTime"] is not None
            else GENERATION_DATETIME
        )

        if not (
            admission_start
            <= episode_start
            <= episode_end
            <= admission_end
        ):
            invalid_episode_ids.append(episode_id)

    for admission_id, sequences in sequences_by_admission.items():
        expected = list(
            range(1, len(sequences) + 1)
        )

        if sorted(sequences) != expected:
            raise GenerationValidationError(
                f"Admission {admission_id} has invalid episode sequences."
            )

    if invalid_episode_ids:
        raise GenerationValidationError(
            "Invalid consultant episodes were generated: "
            + ", ".join(
                str(episode_id)
                for episode_id in invalid_episode_ids[:20]
            )
        )


def _validate_child_activity(
    episodes: list[dict[str, Any]],
    diagnoses: list[dict[str, Any]],
    procedures: list[dict[str, Any]],
) -> None:
    """Validate diagnosis and procedure chronology and sequencing."""

    episode_lookup = {
        int(row["ConsultantEpisodeId"]): row
        for row in episodes
    }

    diagnosis_sequences: dict[int, list[int]] = {}
    diagnosis_primary_counts: dict[int, int] = {}

    for diagnosis in diagnoses:
        episode_id = int(
            diagnosis["ConsultantEpisodeId"]
        )

        episode = episode_lookup.get(episode_id)

        if episode is None:
            raise GenerationValidationError(
                f"Diagnosis {diagnosis['DiagnosisId']} has no episode."
            )

        sequence = int(diagnosis["DiagnosisSequence"])

        diagnosis_sequences.setdefault(
            episode_id,
            [],
        ).append(sequence)

        diagnosis_primary_counts[episode_id] = (
            diagnosis_primary_counts.get(episode_id, 0)
            + int(diagnosis["IsPrimaryDiagnosis"])
        )

        diagnosis_date = date.fromisoformat(
            str(diagnosis["DiagnosisDate"])
        )

        episode_start_date = datetime.fromisoformat(
            str(episode["EpisodeStartDateTime"])
        ).date()

        episode_end_date = (
            datetime.fromisoformat(
                str(episode["EpisodeEndDateTime"])
            ).date()
            if episode["EpisodeEndDateTime"] is not None
            else GENERATION_DATETIME.date()
        )

        if not (
            episode_start_date
            <= diagnosis_date
            <= episode_end_date
        ):
            raise GenerationValidationError(
                f"Diagnosis {diagnosis['DiagnosisId']} is outside its episode."
            )

    for episode_id, sequences in diagnosis_sequences.items():
        if sorted(sequences) != list(
            range(1, len(sequences) + 1)
        ):
            raise GenerationValidationError(
                f"Episode {episode_id} has invalid diagnosis sequences."
            )

        if diagnosis_primary_counts[episode_id] != 1:
            raise GenerationValidationError(
                f"Episode {episode_id} must have one primary diagnosis."
            )

    procedure_sequences: dict[int, list[int]] = {}
    procedure_primary_counts: dict[int, int] = {}

    for procedure in procedures:
        episode_id = int(
            procedure["ConsultantEpisodeId"]
        )

        episode = episode_lookup.get(episode_id)

        if episode is None:
            raise GenerationValidationError(
                f"Procedure {procedure['ProcedureId']} has no episode."
            )

        sequence = int(procedure["ProcedureSequence"])

        procedure_sequences.setdefault(
            episode_id,
            [],
        ).append(sequence)

        procedure_primary_counts[episode_id] = (
            procedure_primary_counts.get(episode_id, 0)
            + int(procedure["IsPrimaryProcedure"])
        )

        procedure_datetime = datetime.fromisoformat(
            str(procedure["ProcedureDateTime"])
        )

        episode_start = datetime.fromisoformat(
            str(episode["EpisodeStartDateTime"])
        )

        episode_end = (
            datetime.fromisoformat(
                str(episode["EpisodeEndDateTime"])
            )
            if episode["EpisodeEndDateTime"] is not None
            else GENERATION_DATETIME
        )

        if not (
            episode_start
            <= procedure_datetime
            <= episode_end
        ):
            raise GenerationValidationError(
                f"Procedure {procedure['ProcedureId']} is outside its episode."
            )

    for episode_id, sequences in procedure_sequences.items():
        if sorted(sequences) != list(
            range(1, len(sequences) + 1)
        ):
            raise GenerationValidationError(
                f"Episode {episode_id} has invalid procedure sequences."
            )

        if procedure_primary_counts[episode_id] != 1:
            raise GenerationValidationError(
                f"Episode {episode_id} must have one primary procedure "
                "when procedures exist."
            )


def _validate_ward_stays(
    admissions: list[dict[str, Any]],
    ward_stays: list[dict[str, Any]],
) -> None:
    """Validate ward-stay sequencing and chronology."""

    admission_lookup = {
        int(row["AdmissionId"]): row
        for row in admissions
    }

    stays_by_admission: dict[
        int,
        list[dict[str, Any]],
    ] = {}

    for stay in ward_stays:
        stays_by_admission.setdefault(
            int(stay["AdmissionId"]),
            [],
        ).append(stay)

    for admission_id, admission in admission_lookup.items():
        stays = sorted(
            stays_by_admission.get(admission_id, []),
            key=lambda row: int(row["WardStaySequence"]),
        )

        if not stays:
            raise GenerationValidationError(
                f"Admission {admission_id} has no ward stays."
            )

        sequences = [
            int(row["WardStaySequence"])
            for row in stays
        ]

        if sequences != list(
            range(1, len(stays) + 1)
        ):
            raise GenerationValidationError(
                f"Admission {admission_id} has invalid ward sequences."
            )

        if int(stays[0]["AdmissionWardFlag"]) != 1:
            raise GenerationValidationError(
                f"Admission {admission_id} has no admission ward."
            )

        admission_is_open = (
            admission["DischargeDateTime"] is None
        )

        if admission_is_open:
            if stays[-1]["WardEndDateTime"] is not None:
                raise GenerationValidationError(
                    f"Open admission {admission_id} has no open ward stay."
                )

            if int(stays[-1]["DischargeWardFlag"]) != 0:
                raise GenerationValidationError(
                    f"Open admission {admission_id} has a discharge ward."
                )
        else:
            if int(stays[-1]["DischargeWardFlag"]) != 1:
                raise GenerationValidationError(
                    f"Discharged admission {admission_id} has no "
                    "discharge ward."
                )

        previous_end: datetime | None = None

        for stay in stays:
            start_datetime = datetime.fromisoformat(
                str(stay["WardStartDateTime"])
            )

            end_value = stay["WardEndDateTime"]

            end_datetime = (
                datetime.fromisoformat(str(end_value))
                if end_value is not None
                else None
            )

            if previous_end is not None and start_datetime != previous_end:
                raise GenerationValidationError(
                    f"Admission {admission_id} has a ward movement gap "
                    "or overlap."
                )

            previous_end = end_datetime


def generate_patient_journey_data(
    config: GeneratorConfig,
    random_generator: Random,
) -> dict[str, list[dict[str, Any]]]:
    """Generate and validate deterministic valid patient journeys."""

    inputs = _load_inputs(config)

    eligible_patients = _eligible_patients(
        patients=inputs["patients"],
        patient_merges=inputs["patient_merges"],
    )

    admissions = _generate_admissions(
        random_generator=random_generator,
        eligible_patients=eligible_patients,
        organisations=inputs["organisations"],
        sites=inputs["sites"],
    )

    consultant_episodes = _generate_consultant_episodes(
        random_generator=random_generator,
        admissions=admissions,
        consultants=inputs["consultants"],
    )

    admissions_by_id = {
        int(row["AdmissionId"]): row
        for row in admissions
    }

    diagnoses = _generate_diagnoses(
        random_generator=random_generator,
        consultant_episodes=consultant_episodes,
    )

    procedures = _generate_procedures(
        random_generator=random_generator,
        consultant_episodes=consultant_episodes,
        admissions_by_id=admissions_by_id,
    )

    ward_stays = _generate_ward_stays(
        random_generator=random_generator,
        admissions=admissions,
        wards=inputs["wards"],
    )

    eligible_patient_ids = {
        int(row["PatientId"])
        for row in eligible_patients
    }

    _validate_admissions(
        admissions=admissions,
        eligible_patient_ids=eligible_patient_ids,
    )

    _validate_episodes(
        admissions=admissions,
        episodes=consultant_episodes,
    )

    _validate_child_activity(
        episodes=consultant_episodes,
        diagnoses=diagnoses,
        procedures=procedures,
    )

    _validate_ward_stays(
        admissions=admissions,
        ward_stays=ward_stays,
    )

    return {
        "admission": admissions,
        "consultant_episode": consultant_episodes,
        "diagnosis": diagnoses,
        "procedure": procedures,
        "ward_stay": ward_stays,
    }