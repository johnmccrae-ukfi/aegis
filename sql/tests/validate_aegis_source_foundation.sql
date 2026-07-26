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

-- Additional PAS admitted-patient tables

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Diagnosis exists',
    CASE
        WHEN OBJECT_ID(N'pas.Diagnosis', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.Diagnosis';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Procedure exists',
    CASE
        WHEN OBJECT_ID(N'pas.Procedure', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.Procedure';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.WardStay exists',
    CASE
        WHEN OBJECT_ID(N'pas.WardStay', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.WardStay';

-- Additional PAS foreign keys

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Diagnosis links to pas.ConsultantEpisode',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Diagnosis_ConsultantEpisode'
              AND parent_object_id = OBJECT_ID(N'pas.Diagnosis')
              AND referenced_object_id = OBJECT_ID(N'pas.ConsultantEpisode')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Diagnosis_ConsultantEpisode';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Procedure links to pas.ConsultantEpisode',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Procedure_ConsultantEpisode'
              AND parent_object_id = OBJECT_ID(N'pas.Procedure')
              AND referenced_object_id = OBJECT_ID(N'pas.ConsultantEpisode')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Procedure_ConsultantEpisode';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Procedure links to ref.Consultant',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Procedure_Consultant'
              AND parent_object_id = OBJECT_ID(N'pas.Procedure')
              AND referenced_object_id = OBJECT_ID(N'ref.Consultant')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Procedure_Consultant';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.Procedure links to ref.Site',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_Procedure_Site'
              AND parent_object_id = OBJECT_ID(N'pas.Procedure')
              AND referenced_object_id = OBJECT_ID(N'ref.Site')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_Procedure_Site';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.WardStay links to pas.Admission',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_WardStay_Admission'
              AND parent_object_id = OBJECT_ID(N'pas.WardStay')
              AND referenced_object_id = OBJECT_ID(N'pas.Admission')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_WardStay_Admission';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.WardStay links to ref.Ward',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_WardStay_Ward'
              AND parent_object_id = OBJECT_ID(N'pas.WardStay')
              AND referenced_object_id = OBJECT_ID(N'ref.Ward')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_WardStay_Ward';

-- Patient identity tables

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier exists',
    CASE
        WHEN OBJECT_ID(N'pas.PatientIdentifier', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.PatientIdentifier';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge exists',
    CASE
        WHEN OBJECT_ID(N'pas.PatientMerge', N'U') IS NOT NULL THEN 1
        ELSE 0
    END,
    N'Expected table: pas.PatientMerge';

-- PatientIdentifier columns

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier.PatientId is INT NOT NULL',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND c.name = N'PatientId'
              AND ty.name = N'int'
              AND c.is_nullable = 0
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientIdentifier.PatientId INT NOT NULL';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier.IdentifierValue is NVARCHAR(100) NOT NULL',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND c.name = N'IdentifierValue'
              AND ty.name = N'nvarchar'
              AND c.max_length = 200
              AND c.is_nullable = 0
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientIdentifier.IdentifierValue NVARCHAR(100) NOT NULL';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier.IdentifierTypeCode is VARCHAR(30) NOT NULL',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND c.name = N'IdentifierTypeCode'
              AND ty.name = N'varchar'
              AND c.max_length = 30
              AND c.is_nullable = 0
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientIdentifier.IdentifierTypeCode VARCHAR(30) NOT NULL';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier.IsCurrent is nullable BIT',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND c.name = N'IsCurrent'
              AND ty.name = N'bit'
              AND c.is_nullable = 1
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientIdentifier.IsCurrent BIT NULL';

-- PatientMerge columns

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge.SurvivingPatientId is INT NOT NULL',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientMerge')
              AND c.name = N'SurvivingPatientId'
              AND ty.name = N'int'
              AND c.is_nullable = 0
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientMerge.SurvivingPatientId INT NOT NULL';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge.SupersededPatientId is INT NOT NULL',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientMerge')
              AND c.name = N'SupersededPatientId'
              AND ty.name = N'int'
              AND c.is_nullable = 0
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientMerge.SupersededPatientId INT NOT NULL';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge.MergeDateTime is DATETIME2(0) NOT NULL',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientMerge')
              AND c.name = N'MergeDateTime'
              AND ty.name = N'datetime2'
              AND c.scale = 0
              AND c.is_nullable = 0
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientMerge.MergeDateTime DATETIME2(0) NOT NULL';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge.SourceMessageControlId is nullable VARCHAR(100)',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            INNER JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
            WHERE c.object_id = OBJECT_ID(N'pas.PatientMerge')
              AND c.name = N'SourceMessageControlId'
              AND ty.name = N'varchar'
              AND c.max_length = 100
              AND c.is_nullable = 1
        )
        THEN 1
        ELSE 0
    END,
    N'Expected column: pas.PatientMerge.SourceMessageControlId VARCHAR(100) NULL';

-- Patient identity primary keys

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier primary key exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.key_constraints
            WHERE name = N'PK_pas_PatientIdentifier'
              AND parent_object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND type = N'PK'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected primary key: PK_pas_PatientIdentifier';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge primary key exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.key_constraints
            WHERE name = N'PK_pas_PatientMerge'
              AND parent_object_id = OBJECT_ID(N'pas.PatientMerge')
              AND type = N'PK'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected primary key: PK_pas_PatientMerge';

-- Patient identity foreign keys

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier links to pas.Patient',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_PatientIdentifier_Patient'
              AND parent_object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND referenced_object_id = OBJECT_ID(N'pas.Patient')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_PatientIdentifier_Patient';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge surviving patient links to pas.Patient',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_PatientMerge_SurvivingPatient'
              AND parent_object_id = OBJECT_ID(N'pas.PatientMerge')
              AND referenced_object_id = OBJECT_ID(N'pas.Patient')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_PatientMerge_SurvivingPatient';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge superseded patient links to pas.Patient',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.foreign_keys
            WHERE name = N'FK_pas_PatientMerge_SupersededPatient'
              AND parent_object_id = OBJECT_ID(N'pas.PatientMerge')
              AND referenced_object_id = OBJECT_ID(N'pas.Patient')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected foreign key: FK_pas_PatientMerge_SupersededPatient';

-- Patient identity indexes

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier PatientId index exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND name = N'IX_pas_PatientIdentifier_PatientId'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected index: IX_pas_PatientIdentifier_PatientId';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier identifier-value index exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = OBJECT_ID(N'pas.PatientIdentifier')
              AND name = N'IX_pas_PatientIdentifier_IdentifierValue'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected index: IX_pas_PatientIdentifier_IdentifierValue';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge surviving-patient index exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = OBJECT_ID(N'pas.PatientMerge')
              AND name = N'IX_pas_PatientMerge_SurvivingPatientId'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected index: IX_pas_PatientMerge_SurvivingPatientId';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge superseded-patient index exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = OBJECT_ID(N'pas.PatientMerge')
              AND name = N'IX_pas_PatientMerge_SupersededPatientId'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected index: IX_pas_PatientMerge_SupersededPatientId';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge merge-date index exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = OBJECT_ID(N'pas.PatientMerge')
              AND name = N'IX_pas_PatientMerge_MergeDateTime'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected index: IX_pas_PatientMerge_MergeDateTime';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge message-control index exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = OBJECT_ID(N'pas.PatientMerge')
              AND name = N'IX_pas_PatientMerge_SourceMessageControlId'
        )
        THEN 1
        ELSE 0
    END,
    N'Expected index: IX_pas_PatientMerge_SourceMessageControlId';

-- Patient identity defaults

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientIdentifier CreatedAtUtc default exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.default_constraints
            WHERE name = N'DF_pas_PatientIdentifier_CreatedAtUtc'
              AND parent_object_id = OBJECT_ID(N'pas.PatientIdentifier')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected default constraint: DF_pas_PatientIdentifier_CreatedAtUtc';

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas.PatientMerge CreatedAtUtc default exists',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM sys.default_constraints
            WHERE name = N'DF_pas_PatientMerge_CreatedAtUtc'
              AND parent_object_id = OBJECT_ID(N'pas.PatientMerge')
        )
        THEN 1
        ELSE 0
    END,
    N'Expected default constraint: DF_pas_PatientMerge_CreatedAtUtc';

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