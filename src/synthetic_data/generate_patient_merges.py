"""Generate Aegis patient-merge source events."""

from datetime import datetime, timezone

from synthetic_data.config import GeneratorConfig
from synthetic_data.generators.patient_merge_data import (
    MERGE_COUNT,
    generate_patient_merge_data,
)
from synthetic_data.utilities.output_writer import (
    write_csv,
    write_json,
)


PATIENT_MERGE_COLUMNS = [
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
]


def main() -> None:
    """Generate and write patient-merge events."""

    config = GeneratorConfig()

    print("Aegis patient-merge generator started.")
    print(f"Expected merge count: {MERGE_COUNT}")

    merge_rows = generate_patient_merge_data(
        config=config,
    )

    output_path = (
        config.pas_output_directory
        / "patient_merge.csv"
    )

    row_count = write_csv(
        output_path=output_path,
        rows=merge_rows,
        fieldnames=PATIENT_MERGE_COLUMNS,
    )

    print(
        f"Wrote {row_count} rows: {output_path}"
    )

    summary = {
        "project": "Aegis Clinical Data Platform",
        "generator": "Synthetic PAS Patient Merge Generator",
        "generation_stage": "Stage 3 - patient merge events",
        "generation_status": "SUCCESS",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(
            timespec="seconds"
        ),
        "patient_merge_count": row_count,
        "merge_reason_code": "DUPLICATE_RECORD",
        "source_system_code": "AEGIS_LEGACY_PAS",
        "message_type": "ADT",
        "trigger_event": "A40",
    }

    summary_path = (
        config.manifest_output_directory
        / "patient_merge_generation_summary.json"
    )

    write_json(
        output_path=summary_path,
        payload=summary,
    )

    print(
        f"Wrote generation summary: {summary_path}"
    )
    print(
        "Aegis patient-merge generation completed successfully."
    )


if __name__ == "__main__":
    main()