"""Generate Stage 1 Aegis synthetic patients and current identifiers."""

from datetime import datetime, timezone
from random import Random

from faker import Faker

from synthetic_data.config import GeneratorConfig
from synthetic_data.generators.patient_data import generate_patient_data
from synthetic_data.utilities.output_writer import write_csv, write_json


PATIENT_FILE_DEFINITIONS = {
    "patient": {
        "filename": "patient.csv",
        "fieldnames": [
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
        ],
    },
    "patient_identifier": {
        "filename": "patient_identifier.csv",
        "fieldnames": [
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
        ],
    },
}


def _write_patient_files(
    config: GeneratorConfig,
    patient_data: dict[str, list[dict[str, object]]],
) -> dict[str, int]:
    """Write generated patient-domain datasets to CSV files."""

    written_counts: dict[str, int] = {}

    for dataset_name, file_definition in PATIENT_FILE_DEFINITIONS.items():
        output_path = (
            config.pas_output_directory
            / str(file_definition["filename"])
        )

        row_count = write_csv(
            output_path=output_path,
            rows=patient_data[dataset_name],
            fieldnames=list(file_definition["fieldnames"]),
        )

        written_counts[dataset_name] = row_count

        print(f"Wrote {row_count} rows: {output_path}")

    return written_counts


def _write_patient_generation_summary(
    config: GeneratorConfig,
    written_counts: dict[str, int],
) -> None:
    """Write a machine-readable Stage 1 patient-generation summary."""

    summary = {
        "project": "Aegis Clinical Data Platform",
        "generator": "Synthetic PAS Patient Generator",
        "generation_stage": "Stage 1 - valid patients and current identifiers",
        "generation_status": "SUCCESS",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(
            timespec="seconds"
        ),
        "random_seed": config.random_seed,
        "patient_count": written_counts["patient"],
        "patient_identifier_count": written_counts["patient_identifier"],
        "identifiers_per_patient": 2,
        "nhs_number_policy": (
            "All NHS-number-like values are deliberately checksum-invalid."
        ),
        "datasets": written_counts,
        "total_rows": sum(written_counts.values()),
    }

    summary_path = (
        config.manifest_output_directory
        / "patient_generation_stage1_summary.json"
    )

    write_json(
        output_path=summary_path,
        payload=summary,
    )

    print(f"Wrote generation summary: {summary_path}")


def main() -> None:
    """Execute Stage 1 patient generation."""

    config = GeneratorConfig()

    random_generator = Random(config.random_seed)

    faker = Faker("en_GB")
    faker.seed_instance(config.random_seed)

    print("Aegis Stage 1 patient generator started.")
    print(f"Random seed: {config.random_seed}")
    print(f"Patient count: {config.patient_count}")
    print(f"Output directory: {config.pas_output_directory}")

    patient_data = generate_patient_data(
        config=config,
        random_generator=random_generator,
        faker=faker,
    )

    for dataset_name, rows in patient_data.items():
        print(f"Validated {dataset_name}: {len(rows)} rows")

    written_counts = _write_patient_files(
        config=config,
        patient_data=patient_data,
    )

    _write_patient_generation_summary(
        config=config,
        written_counts=written_counts,
    )

    print("Aegis Stage 1 patient generation completed successfully.")


if __name__ == "__main__":
    main()