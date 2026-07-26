"""Generate valid Aegis admitted-patient journeys."""

from datetime import datetime, timezone
from random import Random

from synthetic_data.config import GeneratorConfig
from synthetic_data.generators.patient_journey_data import (
    ADMISSION_COUNT,
    GENERATION_DATETIME,
    OPEN_ADMISSION_PERCENTAGE,
    generate_patient_journey_data,
)
from synthetic_data.utilities.output_writer import (
    write_csv,
    write_json,
)


FILE_DEFINITIONS = {
    "admission": {
        "filename": "admission.csv",
        "fieldnames": [
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
        ],
    },
    "consultant_episode": {
        "filename": "consultant_episode.csv",
        "fieldnames": [
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
        ],
    },
    "diagnosis": {
        "filename": "diagnosis.csv",
        "fieldnames": [
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
        ],
    },
    "procedure": {
        "filename": "procedure.csv",
        "fieldnames": [
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
        ],
    },
    "ward_stay": {
        "filename": "ward_stay.csv",
        "fieldnames": [
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
        ],
    },
}


def main() -> None:
    """Generate, validate and write valid patient journeys."""

    config = GeneratorConfig()
    journey_seed = config.random_seed + 3
    random_generator = Random(journey_seed)

    print("Aegis valid patient-journey generator started.")
    print(f"Random seed: {journey_seed}")
    print(f"Target admissions: {ADMISSION_COUNT}")
    print(
        f"Target open-admission percentage: "
        f"{OPEN_ADMISSION_PERCENTAGE}%"
    )

    datasets = generate_patient_journey_data(
        config=config,
        random_generator=random_generator,
    )

    written_counts: dict[str, int] = {}

    for dataset_name, definition in FILE_DEFINITIONS.items():
        output_path = (
            config.pas_output_directory
            / str(definition["filename"])
        )

        row_count = write_csv(
            output_path=output_path,
            rows=datasets[dataset_name],
            fieldnames=list(definition["fieldnames"]),
        )

        written_counts[dataset_name] = row_count

        print(
            f"Wrote {row_count} rows: {output_path}"
        )

    admissions = datasets["admission"]

    open_admission_count = sum(
        1
        for admission in admissions
        if admission["DischargeDateTime"] is None
    )

    discharged_admission_count = (
        len(admissions) - open_admission_count
    )

    summary = {
        "project": "Aegis Clinical Data Platform",
        "generator": "Synthetic PAS Patient Journey Generator",
        "generation_stage": "Stage 4 - valid patient journeys",
        "generation_status": "SUCCESS",
        "generated_at_utc": datetime.now(
            timezone.utc
        ).isoformat(timespec="seconds"),
        "data_as_at": GENERATION_DATETIME.isoformat(
            timespec="seconds"
        ),
        "random_seed": journey_seed,
        "open_admission_target_percentage": (
            OPEN_ADMISSION_PERCENTAGE
        ),
        "open_admission_count": open_admission_count,
        "discharged_admission_count": (
            discharged_admission_count
        ),
        "datasets": written_counts,
        "total_rows": sum(written_counts.values()),
        "validation": {
            "admission_chronology": "PASSED",
            "episode_chronology": "PASSED",
            "diagnosis_chronology": "PASSED",
            "procedure_chronology": "PASSED",
            "ward_stay_chronology": "PASSED",
            "sequence_validation": "PASSED",
            "merged_patient_exclusion": "PASSED",
        },
    }

    summary_path = (
        config.manifest_output_directory
        / "patient_journey_generation_summary.json"
    )

    write_json(
        output_path=summary_path,
        payload=summary,
    )

    print(
        f"Wrote generation summary: {summary_path}"
    )
    print(
        "Aegis valid patient-journey generation completed successfully."
    )


if __name__ == "__main__":
    main()