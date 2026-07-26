"""Generate controlled PAS journey defects for later SSIS validation."""

from datetime import datetime, timezone

from synthetic_data.config import GeneratorConfig
from synthetic_data.generators.patient_journey_defects import (
    ADMISSION_COLUMNS,
    CONSULTANT_EPISODE_COLUMNS,
    DIAGNOSIS_COLUMNS,
    PROCEDURE_COLUMNS,
    WARD_STAY_COLUMNS,
    generate_patient_journey_defects,
)
from synthetic_data.utilities.output_writer import (
    write_csv,
    write_json,
)


DEFECT_FILE_DEFINITIONS = {
    "admission_defect": {
        "filename": "admission_defects.csv",
        "fieldnames": list(ADMISSION_COLUMNS),
    },
    "consultant_episode_defect": {
        "filename": "consultant_episode_defects.csv",
        "fieldnames": list(CONSULTANT_EPISODE_COLUMNS),
    },
    "diagnosis_defect": {
        "filename": "diagnosis_defects.csv",
        "fieldnames": list(DIAGNOSIS_COLUMNS),
    },
    "procedure_defect": {
        "filename": "procedure_defects.csv",
        "fieldnames": list(PROCEDURE_COLUMNS),
    },
    "ward_stay_defect": {
        "filename": "ward_stay_defects.csv",
        "fieldnames": list(WARD_STAY_COLUMNS),
    },
}


MANIFEST_COLUMNS = [
    "ScenarioCode",
    "Domain",
    "Description",
    "ExpectedOutcome",
    "ExpectedCount",
    "SourceObject",
    "ValidationRule",
]


def main() -> None:
    """Generate and write the controlled journey defect pack."""

    config = GeneratorConfig()

    print("Aegis patient-journey defect generator started.")

    datasets = generate_patient_journey_defects(
        config=config,
    )

    written_counts: dict[str, int] = {}

    for dataset_name, definition in DEFECT_FILE_DEFINITIONS.items():
        output_path = (
            config.defect_output_directory
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

    manifest_path = (
        config.defect_output_directory
        / "patient_journey_defect_manifest.csv"
    )

    manifest_count = write_csv(
        output_path=manifest_path,
        rows=datasets["journey_defect_manifest"],
        fieldnames=MANIFEST_COLUMNS,
    )

    print(
        f"Wrote {manifest_count} rows: {manifest_path}"
    )

    summary = {
        "project": "Aegis Clinical Data Platform",
        "generator": "Synthetic PAS Journey Defect Generator",
        "generation_stage": (
            "Stage 5 - controlled invalid journey records"
        ),
        "generation_status": "SUCCESS",
        "generated_at_utc": datetime.now(
            timezone.utc
        ).isoformat(timespec="seconds"),
        "database_load_policy": (
            "Defect files are inbound SSIS test extracts and are not "
            "loaded directly into Aegis_Source."
        ),
        "scenario_count": manifest_count,
        "datasets": written_counts,
        "total_defect_rows": sum(written_counts.values()),
        "expected_processing_outcome": "QUARANTINE",
    }

    summary_path = (
        config.manifest_output_directory
        / "patient_journey_defect_generation_summary.json"
    )

    write_json(
        output_path=summary_path,
        payload=summary,
    )

    print(
        f"Wrote generation summary: {summary_path}"
    )
    print(
        "Aegis patient-journey defect generation completed successfully."
    )


if __name__ == "__main__":
    main()