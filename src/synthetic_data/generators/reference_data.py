"""Generate deterministic Aegis PAS reference datasets."""

from datetime import date, datetime, timezone
from random import Random

from faker import Faker

from synthetic_data.config import GeneratorConfig
from synthetic_data.validation.generation_validation import (
    validate_expected_row_count,
    validate_required_values,
    validate_unique_values,
)


REFERENCE_START_DATE = date(2020, 1, 1)
REFERENCE_CREATED_AT = datetime(2026, 7, 25, 9, 0, 0, tzinfo=timezone.utc)


SPECIALTY_DEFINITIONS = [
    ("SPC001", "100", "General Surgery", "SURGICAL"),
    ("SPC002", "110", "Trauma and Orthopaedics", "SURGICAL"),
    ("SPC003", "300", "General Medicine", "MEDICAL"),
    ("SPC004", "320", "Cardiology", "MEDICAL"),
    ("SPC005", "340", "Respiratory Medicine", "MEDICAL"),
    ("SPC006", "350", "Infectious Diseases", "MEDICAL"),
    ("SPC007", "400", "Neurology", "MEDICAL"),
    ("SPC008", "430", "Geriatric Medicine", "MEDICAL"),
    ("SPC009", "501", "Obstetrics", "WOMENS"),
    ("SPC010", "502", "Gynaecology", "WOMENS"),
    ("SPC011", "420", "Paediatrics", "CHILDRENS"),
    ("SPC012", "180", "Accident and Emergency", "EMERGENCY"),
]


WARD_TYPE_CODES = [
    "ACUTE",
    "ASSESSMENT",
    "CRITICAL_CARE",
    "DAY_CASE",
    "MATERNITY",
    "PAEDIATRIC",
    "REHABILITATION",
]


def _timestamp_text(value: datetime) -> str:
    """Return a SQL-compatible datetime string without a timezone suffix."""

    return value.replace(tzinfo=None).isoformat(timespec="seconds")


def _generate_organisations(
    config: GeneratorConfig,
) -> list[dict[str, object]]:
    """Generate synthetic organisations."""

    organisation_names = [
        "Aegis University Hospitals NHS Trust",
        "North Aegis Community Health Partnership",
        "Aegis Integrated Care Services",
    ]

    organisation_types = [
        "ACUTE_TRUST",
        "COMMUNITY",
        "CARE_SERVICE",
    ]

    rows: list[dict[str, object]] = []

    for index in range(config.organisation_count):
        organisation_number = index + 1

        rows.append(
            {
                "OrganisationId": organisation_number,
                "OrganisationCode": f"ORG{organisation_number:03d}",
                "NationalOrganisationCode": None,
                "OrganisationName": organisation_names[index],
                "OrganisationTypeCode": organisation_types[index],
                "ParentOrganisationCode": None,
                "Postcode": f"AE{organisation_number} 0AA",
                "EffectiveFromDate": REFERENCE_START_DATE.isoformat(),
                "EffectiveToDate": None,
                "RecordCreatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "RecordUpdatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "IsDeleted": 0,
            }
        )

    return rows


def _generate_sites(
    config: GeneratorConfig,
    organisations: list[dict[str, object]],
) -> list[dict[str, object]]:
    """Generate synthetic hospital and community sites."""

    site_names = [
        "Aegis General Hospital",
        "North Aegis Hospital",
        "Aegis Women and Children Centre",
        "Aegis Community Hospital",
        "Aegis Diagnostic Centre",
    ]

    rows: list[dict[str, object]] = []

    for index in range(config.site_count):
        site_number = index + 1
        organisation = organisations[index % len(organisations)]

        rows.append(
            {
                "SiteId": site_number,
                "OrganisationId": organisation["OrganisationId"],
                "SiteCode": f"SITE{site_number:03d}",
                "NationalSiteCode": None,
                "SiteName": site_names[index],
                "AddressLine1": f"{site_number} Aegis Campus",
                "AddressLine2": "Migration District",
                "AddressLine3": None,
                "Postcode": f"AE{site_number} {site_number}ZZ",
                "EffectiveFromDate": REFERENCE_START_DATE.isoformat(),
                "EffectiveToDate": None,
                "RecordCreatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "RecordUpdatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "IsDeleted": 0,
            }
        )

    return rows


def _generate_specialties(
    config: GeneratorConfig,
) -> list[dict[str, object]]:
    """Generate synthetic specialties."""

    if config.specialty_count > len(SPECIALTY_DEFINITIONS):
        raise ValueError(
            f"specialty_count cannot exceed {len(SPECIALTY_DEFINITIONS)} "
            "with the current controlled specialty list."
        )

    rows: list[dict[str, object]] = []

    for index, definition in enumerate(
        SPECIALTY_DEFINITIONS[: config.specialty_count],
        start=1,
    ):
        specialty_code, national_code, specialty_name, specialty_type = definition

        rows.append(
            {
                "SpecialtyId": index,
                "SpecialtyCode": specialty_code,
                "NationalSpecialtyCode": national_code,
                "SpecialtyName": specialty_name,
                "SpecialtyTypeCode": specialty_type,
                "ParentSpecialtyCode": None,
                "EffectiveFromDate": REFERENCE_START_DATE.isoformat(),
                "EffectiveToDate": None,
                "RecordCreatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "RecordUpdatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "IsDeleted": 0,
            }
        )

    return rows


def _generate_consultants(
    config: GeneratorConfig,
    random_generator: Random,
    faker: Faker,
    organisations: list[dict[str, object]],
    specialties: list[dict[str, object]],
) -> list[dict[str, object]]:
    """Generate synthetic consultant records."""

    rows: list[dict[str, object]] = []

    for index in range(config.consultant_count):
        consultant_number = index + 1
        organisation = random_generator.choice(organisations)
        specialty = random_generator.choice(specialties)

        given_name = faker.first_name()
        family_name = faker.last_name()
        title_code = random_generator.choice(["DR", "MR", "MS", "MRS"])

        rows.append(
            {
                "ConsultantId": consultant_number,
                "OrganisationId": organisation["OrganisationId"],
                "MainSpecialtyId": specialty["SpecialtyId"],
                "ConsultantCode": f"CONS{consultant_number:04d}",
                "NationalConsultantCode": None,
                "TitleCode": title_code,
                "FamilyName": family_name,
                "GivenName": given_name,
                "DisplayName": f"{title_code} {given_name} {family_name}",
                "EffectiveFromDate": REFERENCE_START_DATE.isoformat(),
                "EffectiveToDate": None,
                "RecordCreatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "RecordUpdatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "IsDeleted": 0,
            }
        )

    return rows


def _generate_wards(
    config: GeneratorConfig,
    random_generator: Random,
    sites: list[dict[str, object]],
    specialties: list[dict[str, object]],
) -> list[dict[str, object]]:
    """Generate synthetic ward records."""

    rows: list[dict[str, object]] = []

    for index in range(config.ward_count):
        ward_number = index + 1
        site = sites[index % len(sites)]
        specialty = random_generator.choice(specialties)
        ward_type = random_generator.choice(WARD_TYPE_CODES)
        bed_capacity = random_generator.randint(12, 36)

        rows.append(
            {
                "WardId": ward_number,
                "SiteId": site["SiteId"],
                "WardCode": f"WARD{ward_number:03d}",
                "WardName": f"Aegis Ward {ward_number:02d}",
                "WardTypeCode": ward_type,
                "SpecialtyId": specialty["SpecialtyId"],
                "BedCapacity": bed_capacity,
                "EffectiveFromDate": REFERENCE_START_DATE.isoformat(),
                "EffectiveToDate": None,
                "RecordCreatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "RecordUpdatedAt": _timestamp_text(REFERENCE_CREATED_AT),
                "IsDeleted": 0,
            }
        )

    return rows


def _validate_reference_data(
    config: GeneratorConfig,
    datasets: dict[str, list[dict[str, object]]],
) -> None:
    """Validate generated reference datasets."""

    validate_expected_row_count(
        "organisation",
        datasets["organisation"],
        config.organisation_count,
    )
    validate_expected_row_count(
        "site",
        datasets["site"],
        config.site_count,
    )
    validate_expected_row_count(
        "specialty",
        datasets["specialty"],
        config.specialty_count,
    )
    validate_expected_row_count(
        "consultant",
        datasets["consultant"],
        config.consultant_count,
    )
    validate_expected_row_count(
        "ward",
        datasets["ward"],
        config.ward_count,
    )

    validate_unique_values(
        "organisation",
        datasets["organisation"],
        "OrganisationCode",
    )
    validate_unique_values(
        "site",
        datasets["site"],
        "SiteCode",
    )
    validate_unique_values(
        "specialty",
        datasets["specialty"],
        "SpecialtyCode",
    )
    validate_unique_values(
        "consultant",
        datasets["consultant"],
        "ConsultantCode",
    )
    validate_unique_values(
        "ward",
        datasets["ward"],
        "WardCode",
    )

    validate_required_values(
        "organisation",
        datasets["organisation"],
        [
            "OrganisationCode",
            "OrganisationName",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )
    validate_required_values(
        "site",
        datasets["site"],
        [
            "OrganisationId",
            "SiteCode",
            "SiteName",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )
    validate_required_values(
        "specialty",
        datasets["specialty"],
        [
            "SpecialtyCode",
            "SpecialtyName",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )
    validate_required_values(
        "consultant",
        datasets["consultant"],
        [
            "ConsultantCode",
            "DisplayName",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )
    validate_required_values(
        "ward",
        datasets["ward"],
        [
            "SiteId",
            "WardCode",
            "WardName",
            "RecordCreatedAt",
            "RecordUpdatedAt",
            "IsDeleted",
        ],
    )


def generate_reference_data(
    config: GeneratorConfig,
    random_generator: Random,
    faker: Faker,
) -> dict[str, list[dict[str, object]]]:
    """Generate and validate deterministic Aegis reference datasets."""

    organisations = _generate_organisations(config)

    sites = _generate_sites(
        config=config,
        organisations=organisations,
    )

    specialties = _generate_specialties(config)

    consultants = _generate_consultants(
        config=config,
        random_generator=random_generator,
        faker=faker,
        organisations=organisations,
        specialties=specialties,
    )

    wards = _generate_wards(
        config=config,
        random_generator=random_generator,
        sites=sites,
        specialties=specialties,
    )

    datasets = {
        "organisation": organisations,
        "site": sites,
        "specialty": specialties,
        "consultant": consultants,
        "ward": wards,
    }

    _validate_reference_data(
        config=config,
        datasets=datasets,
    )

    return datasets