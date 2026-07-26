"""Configuration for the Aegis synthetic PAS data generator."""

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class GeneratorConfig:
    """Immutable configuration for one synthetic-data generation run."""

    random_seed: int = 20260725

    organisation_count: int = 3
    site_count: int = 5
    specialty_count: int = 12
    consultant_count: int = 36
    ward_count: int = 24

    patient_count: int = 1_000
    target_merge_count: int = 25
    target_defect_count: int = 40

    repository_root: Path = Path(__file__).resolve().parents[2]

    @property
    def output_root(self) -> Path:
        """Return the root directory for locally generated data."""

        return self.repository_root / "data" / "generated"

    @property
    def reference_output_directory(self) -> Path:
        """Return the output directory for reference datasets."""

        return self.output_root / "reference"

    @property
    def pas_output_directory(self) -> Path:
        """Return the output directory for PAS datasets."""

        return self.output_root / "pas"

    @property
    def defect_output_directory(self) -> Path:
        """Return the output directory for deliberate defect datasets."""

        return self.output_root / "defects"

    @property
    def manifest_output_directory(self) -> Path:
        """Return the output directory for manifests and run summaries."""

        return self.output_root / "manifests"