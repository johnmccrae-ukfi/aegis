/*
    Aegis Source Foundation Validation

    Confirms that the initial source database objects and
    reference-data relationships were deployed successfully.
*/

USE [Aegis_Source];
GO

SET NOCOUNT ON;

DECLARE @ValidationResults TABLE
(
    CheckName VARCHAR(150) NOT NULL,
    Passed    BIT          NOT NULL,
    Detail    NVARCHAR(500) NULL
);

-- Schemas

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas schema exists',
    CASE WHEN SCHEMA_ID(N'pas') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: pas';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'epr schema exists',
    CASE WHEN SCHEMA_ID(N'epr') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: epr';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref schema exists',
    CASE WHEN SCHEMA_ID(N'ref') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: ref';

-- PAS tables and columns

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Patient exists',
    CASE
        WHEN OBJECT_ID(N'pas.Patient', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.Patient';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Patient.HospitalNumber exists',
    CASE
        WHEN COL_LENGTH(N'pas.Patient', N'HospitalNumber') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected column: pas.Patient.HospitalNumber';

-- Reference tables

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Organisation exists',
    CASE
        WHEN OBJECT_ID(N'ref.Organisation', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: ref.Organisation';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Site exists',
    CASE
        WHEN OBJECT_ID(N'ref.Site', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: ref.Site';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Specialty exists',
    CASE
        WHEN OBJECT_ID(N'ref.Specialty', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: ref.Specialty';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Consultant exists',
    CASE
        WHEN OBJECT_ID(N'ref.Consultant', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: ref.Consultant';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Ward exists',
    CASE
        WHEN OBJECT_ID(N'ref.Ward', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: ref.Ward';

-- Foreign keys

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Site links to ref.Organisation',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_ref_Site_Organisation'
              AND parent_object_id = OBJECT_ID(N'ref.Site')
              AND referenced_object_id = OBJECT_ID(N'ref.Organisation')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_ref_Site_Organisation';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Consultant links to ref.Organisation',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_ref_Consultant_Organisation'
              AND parent_object_id = OBJECT_ID(N'ref.Consultant')
              AND referenced_object_id = OBJECT_ID(N'ref.Organisation')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_ref_Consultant_Organisation';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Consultant links to ref.Specialty',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_ref_Consultant_MainSpecialty'
              AND parent_object_id = OBJECT_ID(N'ref.Consultant')
              AND referenced_object_id = OBJECT_ID(N'ref.Specialty')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_ref_Consultant_MainSpecialty';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Ward links to ref.Site',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_ref_Ward_Site'
              AND parent_object_id = OBJECT_ID(N'ref.Ward')
              AND referenced_object_id = OBJECT_ID(N'ref.Site')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_ref_Ward_Site';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'ref.Ward links to ref.Specialty',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_ref_Ward_Specialty'
              AND parent_object_id = OBJECT_ID(N'ref.Ward')
              AND referenced_object_id = OBJECT_ID(N'ref.Specialty')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_ref_Ward_Specialty';

    -- PAS admitted-patient tables

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Admission exists',
    CASE
        WHEN OBJECT_ID(N'pas.Admission', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.Admission';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.ConsultantEpisode exists',
    CASE
        WHEN OBJECT_ID(N'pas.ConsultantEpisode', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.ConsultantEpisode';

-- PAS foreign keys

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Admission links to pas.Patient',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Admission_Patient'
              AND parent_object_id = OBJECT_ID(N'pas.Admission')
              AND referenced_object_id = OBJECT_ID(N'pas.Patient')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Admission_Patient';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Admission links to ref.Organisation',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Admission_Organisation'
              AND parent_object_id = OBJECT_ID(N'pas.Admission')
              AND referenced_object_id = OBJECT_ID(N'ref.Organisation')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Admission_Organisation';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Admission links to ref.Site',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Admission_Site'
              AND parent_object_id = OBJECT_ID(N'pas.Admission')
              AND referenced_object_id = OBJECT_ID(N'ref.Site')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Admission_Site';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.ConsultantEpisode links to pas.Admission',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_ConsultantEpisode_Admission'
              AND parent_object_id = OBJECT_ID(N'pas.ConsultantEpisode')
              AND referenced_object_id = OBJECT_ID(N'pas.Admission')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_ConsultantEpisode_Admission';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.ConsultantEpisode links to ref.Consultant',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_ConsultantEpisode_Consultant'
              AND parent_object_id = OBJECT_ID(N'pas.ConsultantEpisode')
              AND referenced_object_id = OBJECT_ID(N'ref.Consultant')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_ConsultantEpisode_Consultant';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.ConsultantEpisode links to main specialty',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_ConsultantEpisode_MainSpecialty'
              AND parent_object_id = OBJECT_ID(N'pas.ConsultantEpisode')
              AND referenced_object_id = OBJECT_ID(N'ref.Specialty')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_ConsultantEpisode_MainSpecialty';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.ConsultantEpisode links to treatment specialty',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_ConsultantEpisode_TreatmentSpecialty'
              AND parent_object_id = OBJECT_ID(N'pas.ConsultantEpisode')
              AND referenced_object_id = OBJECT_ID(N'ref.Specialty')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_ConsultantEpisode_TreatmentSpecialty';


-- Results

SELECT
    CheckName,
    Passed,
    Detail
FROM @ValidationResults
ORDER BY
    CheckName;

IF EXISTS
(
    SELECT 1
    FROM @ValidationResults
    WHERE Passed = 0
)
BEGIN
    THROW 51000, 'Aegis source foundation validation failed.', 1;
END;

PRINT 'Aegis source foundation validation passed.';
GO