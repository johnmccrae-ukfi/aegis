"""Command-line entry point for the Aegis synthetic-data generator."""

from datetime import datetime, timezone
from random import Random

from faker import Faker

from synthetic_data.config import GeneratorConfig
from synthetic_data.generators.reference_data import generate_reference_data
from synthetic_data.utilities.output_writer import write_csv, write_json


REFERENCE_FILE_DEFINITIONS = {
    "organisation": {
        "filename": "organisation.csv",
        "fieldnames": [
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
        ],
    },
    "site": {
        "filename": "site.csv",
        "fieldnames": [
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
        ],
    },
    "specialty": {
        "filename": "specialty.csv",
        "fieldnames": [
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
        ],
    },
    "consultant": {
        "filename": "consultant.csv",
        "fieldnames": [
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
        ],
    },
    "ward": {
        "filename": "ward.csv",
        "fieldnames": [
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
        ],
    },
}


def _write_reference_files(
    config: GeneratorConfig,
    reference_data: dict[str, list[dict[str, object]]],
) -> dict[str, int]:
    """Write generated reference datasets to CSV files."""

    written_counts: dict[str, int] = {}

    for dataset_name, file_definition in REFERENCE_FILE_DEFINITIONS.items():
        output_path = (
            config.reference_output_directory
            / str(file_definition["filename"])
        )

        row_count = write_csv(
            output_path=output_path,
            rows=reference_data[dataset_name],
            fieldnames=list(file_definition["fieldnames"]),
        )

        written_counts[dataset_name] = row_count

        print(f"Wrote {row_count} rows: {output_path}")

    return written_counts


def _write_generation_summary(
    config: GeneratorConfig,
    written_counts: dict[str, int],
) -> None:
    """Write a machine-readable generation summary."""

    generated_at_utc = datetime.now(timezone.utc)

    summary = {
        "project": "Aegis Clinical Data Platform",
        "generator": "Synthetic PAS Data Generator",
        "generation_status": "SUCCESS",
        "generated_at_utc": generated_at_utc.isoformat(timespec="seconds"),
        "random_seed": config.random_seed,
        "python_output_root": str(config.output_root),
        "datasets": written_counts,
        "total_rows": sum(written_counts.values()),
    }

    summary_path = (
        config.manifest_output_directory
        / "reference_generation_summary.json"
    )

    write_json(
        output_path=summary_path,
        payload=summary,
    )

    print(f"Wrote generation summary: {summary_path}")


def main() -> None:
    """Execute one deterministic synthetic-data generation run."""

    config = GeneratorConfig()

    random_generator = Random(config.random_seed)

    faker = Faker("en_GB")
    faker.seed_instance(config.random_seed)

    print("Aegis synthetic-data generator started.")
    print(f"Random seed: {config.random_seed}")
    print(f"Output root: {config.output_root}")

    reference_data = generate_reference_data(
        config=config,
        random_generator=random_generator,
        faker=faker,
    )

    for dataset_name, rows in reference_data.items():
        print(f"Validated {dataset_name}: {len(rows)} rows")

    written_counts = _write_reference_files(
        config=config,
        reference_data=reference_data,
    )

    _write_generation_summary(
        config=config,
        written_counts=written_counts,
    )

    print(
        "Aegis synthetic reference-data generation completed successfully."
    )


if __name__ == "__main__":
    main()