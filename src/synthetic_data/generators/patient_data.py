"""Generate deterministic synthetic Aegis patient and identifier data."""

from datetime import date, datetime, timedelta, timezone
from random import Random
from typing import Any

from faker import Faker

from synthetic_data.config import GeneratorConfig
from synthetic_data.validation.generation_validation import (
    GenerationValidationError,
    validate_expected_row_count,
    validate_required_values,
    validate_unique_values,
)


PATIENT_CREATED_AT = datetime(
    2026,
    7,
    25,
    10,
    0,
    0,
    tzinfo=timezone.utc,
)

PATIENT_IDENTIFIER_EFFECTIVE_START = date(2015, 1, 1)

TITLE_CODES_BY_SEX = {
    "F": ("MS", "MRS", "MISS", "DR"),
    "M": ("MR", "DR"),
    "X": ("MX", "DR"),
}

PATIENT_STATUS_CODES = (
    "ACTIVE",
    "ACTIVE",
    "ACTIVE",
    "ACTIVE",
    "ACTIVE",
    "DECEASED",
)

STREET_NAMES = (
    "Aegis Street",
    "Migration Avenue",
    "Validation Close",
    "Reconciliation Road",
    "Interface Way",
    "Assurance Drive",
    "Synthetic Lane",
    "Data Quality Grove",
)

TOWNS = (
    "North Aegis",
    "South Aegis",
    "East Aegis",
    "West Aegis",
    "Aegis Central",
)

REGISTERED_GP_CODES = tuple(
    f"GP{number:04d}"
    for number in range(1, 51)
)

REGISTERED_PRACTICE_CODES = tuple(
    f"PRAC{number:03d}"
    for number in range(1, 21)
)


def _datetime_text(value: datetime) -> str:
    """Return a SQL-compatible datetime string without timezone information."""

    return value.replace(tzinfo=None).isoformat(timespec="seconds")


def _calculate_nhs_check_digit(first_nine_digits: str) -> int | None:
    """
    Calculate an NHS number check digit.

    Returns None when the modulus result represents an invalid check digit.
    """

    if len(first_nine_digits) != 9 or not first_nine_digits.isdigit():
        raise ValueError(
            "NHS number calculation requires exactly nine numeric digits."
        )

    weighted_total = sum(
        int(digit) * weight
        for digit, weight in zip(
            first_nine_digits,
            range(10, 1, -1),
            strict=True,
        )
    )

    remainder = weighted_total % 11
    check_digit = 11 - remainder

    if check_digit == 11:
        return 0

    if check_digit == 10:
        return None

    return check_digit


def _is_valid_nhs_number(value: str) -> bool:
    """Return True only when a ten-digit value passes NHS checksum validation."""

    if len(value) != 10 or not value.isdigit():
        return False

    expected_check_digit = _calculate_nhs_check_digit(value[:9])

    if expected_check_digit is None:
        return False

    return int(value[-1]) == expected_check_digit


def _generate_invalid_nhs_number(patient_number: int) -> str:
    """
    Generate a unique ten-digit NHS-number-like value that fails validation.

    Each patient receives a unique nine-digit synthetic stem. The final digit
    is then selected so that it cannot equal the valid NHS checksum digit.
    """

    if patient_number < 1 or patient_number > 9_999_999:
        raise ValueError(
            "patient_number must be between 1 and 9,999,999."
        )

    first_nine_digits = f"99{patient_number:07d}"

    valid_check_digit = _calculate_nhs_check_digit(
        first_nine_digits
    )

    if valid_check_digit is None:
        invalid_check_digit = 0
    else:
        invalid_check_digit = (valid_check_digit + 1) % 10

    candidate = first_nine_digits + str(invalid_check_digit)

    if _is_valid_nhs_number(candidate):
        raise GenerationValidationError(
            "Generated NHS-number-like value unexpectedly passed "
            "checksum validation."
        )

    return candidate


def _generate_date_of_birth(
    random_generator: Random,
) -> date:
    """Generate a plausible synthetic date of birth that is not in the future."""

    generation_date = PATIENT_CREATED_AT.date()

    age_group = random_generator.choices(
        population=("CHILD", "ADULT", "OLDER", "VERY_OLD"),
        weights=(12, 53, 27, 8),
        k=1,
    )[0]

    age_ranges = {
        "CHILD": (0, 17),
        "ADULT": (18, 64),
        "OLDER": (65, 84),
        "VERY_OLD": (85, 102),
    }

    minimum_age, maximum_age = age_ranges[age_group]
    age = random_generator.randint(minimum_age, maximum_age)

    approximate_birth_date = generation_date.replace(
        year=generation_date.year - age
    )

    day_offset = random_generator.randint(-182, 182)

    generated_date = approximate_birth_date + timedelta(
        days=day_offset
    )

    return min(generated_date, generation_date)


def _generate_date_of_death(
    random_generator: Random,
    date_of_birth: date,
    patient_status_code: str,
) -> date | None:
    """Generate a valid date of death for deceased synthetic patients."""

    if patient_status_code != "DECEASED":
        return None

    minimum_death_date = max(
        date_of_birth + timedelta(days=1),
        date(2020, 1, 1),
    )

    maximum_death_date = PATIENT_CREATED_AT.date() - timedelta(days=1)

    if minimum_death_date > maximum_death_date:
        return None

    available_days = (maximum_death_date - minimum_death_date).days

    return minimum_death_date + timedelta(
        days=random_generator.randint(0, available_days)
    )


def _generate_postcode(
    patient_number: int,
) -> str:
    """Generate a short synthetic postcode-like value within VARCHAR(8)."""

    district = ((patient_number - 1) % 9) + 1
    sector = ((patient_number - 1) // 9) % 10
    unit_number = ((patient_number - 1) % 99) + 1

    return f"AE{district} {sector}{unit_number:02d}"


def _generate_patient_name(
    faker: Faker,
    sex_code: str,
) -> tuple[str, str]:
    """Generate a synthetic given name and family name."""

    if sex_code == "F":
        given_name = faker.first_name_female()
    elif sex_code == "M":
        given_name = faker.first_name_male()
    else:
        given_name = faker.first_name_nonbinary()

    family_name = faker.last_name()

    return given_name, family_name


def _generate_patients(
    config: GeneratorConfig,
    random_generator: Random,
    faker: Faker,
) -> list[dict[str, Any]]:
    """Generate valid synthetic patient records."""

    rows: list[dict[str, Any]] = []

    for zero_based_index in range(config.patient_count):
        patient_number = zero_based_index + 1

        sex_code = random_generator.choices(
            population=("F", "M", "X"),
            weights=(49, 49, 2),
            k=1,
        )[0]

        given_name, family_name = _generate_patient_name(
            faker=faker,
            sex_code=sex_code,
        )

        patient_status_code = random_generator.choice(
            PATIENT_STATUS_CODES
        )

        date_of_birth = _generate_date_of_birth(
            random_generator=random_generator
        )

        date_of_death = _generate_date_of_death(
            random_generator=random_generator,
            date_of_birth=date_of_birth,
            patient_status_code=patient_status_code,
        )

        if patient_status_code == "DECEASED" and date_of_death is None:
            patient_status_code = "ACTIVE"

        title_code = random_generator.choice(
            TITLE_CODES_BY_SEX[sex_code]
        )

        hospital_number = f"AEG{patient_number:07d}"
        nhs_number = _generate_invalid_nhs_number(patient_number)

        address_number = ((patient_number - 1) % 200) + 1
        street_name = random_generator.choice(STREET_NAMES)
        town_name = random_generator.choice(TOWNS)

        rows.append(
            {
                "PatientId": patient_number,
                "HospitalNumber": hospital_number,
                "NhsNumber": nhs_number,
                "NhsNumberStatusCode": "IV",
                "FamilyName": family_name,
                "GivenName": given_name,
                "MiddleNames": None,
                "TitleCode": title_code,
                "DateOfBirth": date_of_birth.isoformat(),
                "SexCode": sex_code,
                "AddressLine1": f"{address_number} {street_name}",
                "AddressLine2": town_name,
                "AddressLine3": None,
                "Postcode": _generate_postcode(patient_number),
                "RegisteredGpCode": random_generator.choice(
                    REGISTERED_GP_CODES
                ),
                "RegisteredPracticeCode": random_generator.choice(
                    REGISTERED_PRACTICE_CODES
                ),
                "DateOfDeath": (
                    date_of_death.isoformat()
                    if date_of_death is not None
                    else None
                ),
                "PatientStatusCode": patient_status_code,
                "RecordCreatedAt": _datetime_text(PATIENT_CREATED_AT),
                "RecordUpdatedAt": _datetime_text(PATIENT_CREATED_AT),
                "IsDeleted": 0,
            }
        )

    return rows


def _generate_current_identifiers(
    patients: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Generate current hospital and NHS identifiers for every patient."""

    rows: list[dict[str, Any]] = []
    patient_identifier_id = 1

    effective_from_text = PATIENT_IDENTIFIER_EFFECTIVE_START.isoformat()
    created_at_text = _datetime_text(PATIENT_CREATED_AT)

    for patient in patients:
        patient_id = int(patient["PatientId"])

        rows.append(
            {
                "PatientIdentifierId": patient_identifier_id,
                "PatientId": patient_id,
                "IdentifierValue": patient["HospitalNumber"],
                "IdentifierTypeCode": "HOSPITAL_NUMBER",
                "AssigningAuthority": "AEGIS_PAS",
                "EffectiveFromDate": effective_from_text,
                "EffectiveToDate": None,
                "IsCurrent": 1,
                "CreatedAtUtc": created_at_text,
                "UpdatedAtUtc": None,
            }
        )

        patient_identifier_id += 1

        rows.append(
            {
                "PatientIdentifierId": patient_identifier_id,
                "PatientId": patient_id,
                "IdentifierValue": patient["NhsNumber"],
                "IdentifierTypeCode": "NHS_NUMBER",
                "AssigningAuthority": "NHS_SYNTHETIC",
                "EffectiveFromDate": effective_from_text,
                "EffectiveToDate": None,
                "IsCurrent": 1,
                "CreatedAtUtc": created_at_text,
                "UpdatedAtUtc": None,
            }
        )

        patient_identifier_id += 1

    return rows


def _validate_patients(
    config: GeneratorConfig,
    patients: list[dict[str, Any]],
) -> None:
    """Validate the generated patient population."""

    validate_expected_row_count(
        dataset_name="patient",
        rows=patients,
        expected_count=config.patient_count,
    )

    validate_unique_values(
        dataset_name="patient",
        rows=patients,
        key_name="PatientId",
    )

    validate_unique_values(
        dataset_name="patient",
        rows=patients,
        key_name="HospitalNumber",
    )

    validate_unique_values(
        dataset_name="patient",
        rows=patients,
        key_name="NhsNumber",
    )

    validate_required_values(
        dataset_name="patient",
        rows=patients,
        required_keys=[
            "PatientId",
            "HospitalNumber",
            "FamilyName",
            "GivenName",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )

    # Confirm that no generated NHS-number-like value passes
    # the real NHS checksum validation.
    valid_nhs_numbers = [
        str(patient["NhsNumber"])
        for patient in patients
        if _is_valid_nhs_number(str(patient["NhsNumber"]))
    ]

    if valid_nhs_numbers:
        raise GenerationValidationError(
            "Generated patient data contains mathematically valid "
            "NHS numbers."
        )

    # Confirm that no generated date of birth is after the
    # fixed generation date.
    generation_date = PATIENT_CREATED_AT.date()

    future_birth_dates = [
        int(patient["PatientId"])
        for patient in patients
        if date.fromisoformat(
            str(patient["DateOfBirth"])
        ) > generation_date
    ]

    if future_birth_dates:
        raise GenerationValidationError(
            "Generated patients contain future dates of birth: "
            + ", ".join(
                str(patient_id)
                for patient_id in future_birth_dates
            )
        )

    # Confirm that every recorded date of death is on or after
    # the patient's date of birth.
    invalid_death_dates: list[int] = []

    for patient in patients:
        date_of_death_value = patient["DateOfDeath"]

        if date_of_death_value is None:
            continue

        date_of_birth = date.fromisoformat(
            str(patient["DateOfBirth"])
        )
        date_of_death = date.fromisoformat(
            str(date_of_death_value)
        )

        if date_of_death < date_of_birth:
            invalid_death_dates.append(
                int(patient["PatientId"])
            )

    if invalid_death_dates:
        raise GenerationValidationError(
            "Generated patients contain dates of death before dates of birth: "
            + ", ".join(
                str(patient_id)
                for patient_id in invalid_death_dates
            )
        )


def _validate_current_identifiers(
    config: GeneratorConfig,
    identifiers: list[dict[str, Any]],
) -> None:
    """Validate the generated current patient identifiers."""

    expected_identifier_count = config.patient_count * 2

    validate_expected_row_count(
        dataset_name="patient_identifier",
        rows=identifiers,
        expected_count=expected_identifier_count,
    )

    validate_unique_values(
        dataset_name="patient_identifier",
        rows=identifiers,
        key_name="PatientIdentifierId",
    )

    validate_required_values(
        dataset_name="patient_identifier",
        rows=identifiers,
        required_keys=[
            "PatientIdentifierId",
            "PatientId",
            "IdentifierValue",
            "IdentifierTypeCode",
            "IsCurrent",
            "CreatedAtUtc",
        ],
    )

    identifier_pairs = {
        (
            int(identifier["PatientId"]),
            str(identifier["IdentifierTypeCode"]),
        )
        for identifier in identifiers
    }

    expected_pairs = config.patient_count * 2

    if len(identifier_pairs) != expected_pairs:
        raise GenerationValidationError(
            "Each Stage 1 patient must have exactly one current hospital "
            "identifier and one current NHS-number-like identifier."
        )

    noncurrent_identifiers = [
        int(identifier["PatientIdentifierId"])
        for identifier in identifiers
        if int(identifier["IsCurrent"]) != 1
    ]

    if noncurrent_identifiers:
        raise GenerationValidationError(
            "Stage 1 contains unexpected non-current identifiers."
        )


def generate_patient_data(
    config: GeneratorConfig,
    random_generator: Random,
    faker: Faker,
) -> dict[str, list[dict[str, Any]]]:
    """Generate and validate Stage 1 patient-domain datasets."""

    patients = _generate_patients(
        config=config,
        random_generator=random_generator,
        faker=faker,
    )

    identifiers = _generate_current_identifiers(
        patients=patients,
    )

    _validate_patients(
        config=config,
        patients=patients,
    )

    _validate_current_identifiers(
        config=config,
        identifiers=identifiers,
    )

    return {
        "patient": patients,
        "patient_identifier": identifiers,
    }