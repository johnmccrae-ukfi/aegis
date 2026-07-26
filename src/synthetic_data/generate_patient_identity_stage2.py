"""Generate Stage 2 Aegis patient-identity complexity."""

from datetime import datetime, timezone
from random import Random

from synthetic_data.config import GeneratorConfig
from synthetic_data.generators.patient_identity_stage2 import (
    DUPLICATE_IDENTIFIER_SCENARIO_COUNT,
    HISTORIC_IDENTIFIER_COUNT,
    MERGE_READY_PAIR_COUNT,
    generate_patient_identity_stage2,
)
from synthetic_data.utilities.output_writer import write_csv, write_json


PATIENT_IDENTIFIER_COLUMNS = [
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
]


MERGE_READY_COLUMNS = [
    "MergeScenarioCode",
    "SurvivingPatientId",
    "SupersededPatientId",
    "SurvivingHospitalNumber",
    "SupersededHospitalNumber",
    "PlannedMergeReasonCode",
    "PlannedSourceMessageControlId",
    "PlannedSourceSystemCode",
    "Status",
]


DEFECT_MANIFEST_COLUMNS = [
    "ScenarioCode",
    "Domain",
    "Description",
    "ExpectedOutcome",
    "ExpectedCount",
    "SourceObject",
    "ValidationRule",
    "IdentifierValue",
    "FirstPatientId",
    "SecondPatientId",
]


def main() -> None:
    """Generate and write Stage 2 identity datasets."""

    config = GeneratorConfig()
    random_generator = Random(config.random_seed + 2)

    print("Aegis Stage 2 patient-identity generator started.")
    print(f"Random seed: {config.random_seed + 2}")

    datasets = generate_patient_identity_stage2(
        config=config,
        random_generator=random_generator,
    )

    combined_identifier_path = (
        config.pas_output_directory
        / "patient_identifier_stage2.csv"
    )

    combined_identifier_count = write_csv(
        output_path=combined_identifier_path,
        rows=datasets["patient_identifier_stage2"],
        fieldnames=PATIENT_IDENTIFIER_COLUMNS,
    )

    print(
        f"Wrote {combined_identifier_count} rows: "
        f"{combined_identifier_path}"
    )

    merge_ready_path = (
        config.pas_output_directory
        / "merge_ready_pairs.csv"
    )

    merge_ready_count = write_csv(
        output_path=merge_ready_path,
        rows=datasets["merge_ready_pair"],
        fieldnames=MERGE_READY_COLUMNS,
    )

    print(
        f"Wrote {merge_ready_count} rows: "
        f"{merge_ready_path}"
    )

    defect_manifest_path = (
        config.defect_output_directory
        / "patient_identity_defect_manifest.csv"
    )

    defect_manifest_count = write_csv(
        output_path=defect_manifest_path,
        rows=datasets["identity_defect_manifest"],
        fieldnames=DEFECT_MANIFEST_COLUMNS,
    )

    print(
        f"Wrote {defect_manifest_count} rows: "
        f"{defect_manifest_path}"
    )

    summary = {
        "project": "Aegis Clinical Data Platform",
        "generation_stage": (
            "Stage 2 - historic identifiers, duplicate identifiers "
            "and merge-ready pairs"
        ),
        "generation_status": "SUCCESS",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(
            timespec="seconds"
        ),
        "random_seed": config.random_seed + 2,
        "baseline_identifier_count": 2000,
        "historic_identifier_count": HISTORIC_IDENTIFIER_COUNT,
        "duplicate_identifier_scenario_count": (
            DUPLICATE_IDENTIFIER_SCENARIO_COUNT
        ),
        "duplicate_identifier_row_count": (
            DUPLICATE_IDENTIFIER_SCENARIO_COUNT * 2
        ),
        "combined_identifier_count": combined_identifier_count,
        "merge_ready_pair_count": MERGE_READY_PAIR_COUNT,
        "defect_manifest_count": defect_manifest_count,
    }

    summary_path = (
        config.manifest_output_directory
        / "patient_identity_stage2_summary.json"
    )

    write_json(
        output_path=summary_path,
        payload=summary,
    )

    print(f"Wrote generation summary: {summary_path}")
    print(
        "Aegis Stage 2 patient-identity generation completed successfully."
    )


if __name__ == "__main__":
    main()