/*
    Aegis Clinical Data Platform
    Day 2 source-data validation and reconciliation

    Purpose:
      - Validate the complete synthetic Aegis_Source baseline.
      - Reconcile reference, patient-identity and admitted-patient activity.
      - Confirm patient-merge lineage and logical patient counts.
      - Validate chronology, sequencing and primary-code rules.
      - Confirm controlled journey defects have not entered Aegis_Source.
      - Document expected Day 3 SSIS defect-file controls.

    Target:
      DESKTOP-N58JDOH
      Aegis_Source

    Expected loaded baseline:
      ref.Organisation               3
      ref.Site                       5
      ref.Specialty                 12
      ref.Consultant                36
      ref.Ward                      24

      pas.Patient                 1,000
      pas.PatientIdentifier       2,170
      pas.PatientMerge               25
      pas.Admission               1,600
      pas.ConsultantEpisode       3,125
      pas.Diagnosis               7,797
      pas.Procedure               2,150
      pas.WardStay                3,211

    Data as at:
      2026-07-26 10:00:00

    Important:
      The controlled defect files are inbound SSIS test extracts.
      They must not be loaded directly into Aegis_Source.
*/

USE [Aegis_Source];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DataAsAt DATETIME2(0) = '2026-07-26T10:00:00';

DROP TABLE IF EXISTS #ValidationResults;

CREATE TABLE #ValidationResults
(
    CheckId        INT IDENTITY(1, 1) NOT NULL,
    CheckCategory  VARCHAR(50)        NOT NULL,
    CheckName      VARCHAR(250)       NOT NULL,
    ExpectedValue  BIGINT             NOT NULL,
    ActualValue    BIGINT             NOT NULL,
    Passed         BIT                NOT NULL,
    Detail         NVARCHAR(500)      NULL,

    CONSTRAINT PK_ValidationResults
        PRIMARY KEY CLUSTERED (CheckId)
);

-------------------------------------------------------------------------------
-- 1. Reference-data reconciliation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
(
    CheckCategory,
    CheckName,
    ExpectedValue,
    ActualValue,
    Passed,
    Detail
)
SELECT
    'REFERENCE',
    'Organisation row count',
    3,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 3 THEN 1 ELSE 0 END,
    'Expected deterministic synthetic organisation baseline.'
FROM ref.Organisation;

INSERT INTO #ValidationResults
SELECT
    'REFERENCE',
    'Site row count',
    5,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 5 THEN 1 ELSE 0 END,
    'Expected deterministic synthetic site baseline.'
FROM ref.Site;

INSERT INTO #ValidationResults
SELECT
    'REFERENCE',
    'Specialty row count',
    12,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 12 THEN 1 ELSE 0 END,
    'Expected controlled specialty baseline.'
FROM ref.Specialty;

INSERT INTO #ValidationResults
SELECT
    'REFERENCE',
    'Consultant row count',
    36,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 36 THEN 1 ELSE 0 END,
    'Expected deterministic synthetic consultant baseline.'
FROM ref.Consultant;

INSERT INTO #ValidationResults
SELECT
    'REFERENCE',
    'Ward row count',
    24,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 24 THEN 1 ELSE 0 END,
    'Expected deterministic synthetic ward baseline.'
FROM ref.Ward;

-------------------------------------------------------------------------------
-- 2. Patient identity and merge reconciliation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Patient row count',
    1000,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 1000 THEN 1 ELSE 0 END,
    'Physical source patient records before merge resolution.'
FROM pas.Patient;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Patient identifier row count',
    2170,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 2170 THEN 1 ELSE 0 END,
    'Includes current, historic and deliberately duplicated identifiers.'
FROM pas.PatientIdentifier;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Current patient identifier rows',
    2020,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 2020 THEN 1 ELSE 0 END,
    'Two baseline current identifiers per patient plus 20 duplicate-defect rows.'
FROM pas.PatientIdentifier
WHERE IsCurrent = 1;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Closed historic hospital identifiers',
    150,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 150 THEN 1 ELSE 0 END,
    'Historic OLD identifiers must be non-current and have an end date.'
FROM pas.PatientIdentifier
WHERE IdentifierValue LIKE 'OLD%'
  AND IdentifierTypeCode = 'HOSPITAL_NUMBER'
  AND IsCurrent = 0
  AND EffectiveToDate IS NOT NULL;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Patient merge row count',
    25,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 25 THEN 1 ELSE 0 END,
    'Expected ADT A40-style synthetic merge baseline.'
FROM pas.PatientMerge;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Distinct superseded patients',
    25,
    COUNT_BIG(DISTINCT SupersededPatientId),
    CASE
        WHEN COUNT_BIG(DISTINCT SupersededPatientId) = 25
            THEN 1
        ELSE 0
    END,
    'Each merge should supersede one distinct patient.'
FROM pas.PatientMerge;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Logical patients after merge resolution',
    975,
    (
        SELECT COUNT_BIG(*)
        FROM pas.Patient AS p
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM pas.PatientMerge AS pm
            WHERE pm.SupersededPatientId = p.PatientId
        )
    ),
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM pas.Patient AS p
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM pas.PatientMerge AS pm
                WHERE pm.SupersededPatientId = p.PatientId
            )
        ) = 975
            THEN 1
        ELSE 0
    END,
    'Physical patients minus distinct superseded merge records.';

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Duplicate current hospital-identifier scenarios',
    10,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 10 THEN 1 ELSE 0 END,
    'Each DUP value must be assigned to exactly two different patients.'
FROM
(
    SELECT
        IdentifierValue
    FROM pas.PatientIdentifier
    WHERE IdentifierValue LIKE 'DUP%'
      AND IdentifierTypeCode = 'HOSPITAL_NUMBER'
      AND IsCurrent = 1
    GROUP BY
        IdentifierValue
    HAVING
        COUNT_BIG(*) = 2
        AND COUNT_BIG(DISTINCT PatientId) = 2
) AS DuplicateIdentifierScenario;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Duplicate current hospital-identifier rows',
    20,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 20 THEN 1 ELSE 0 END,
    'Ten deliberate duplicate scenarios with two rows each.'
FROM pas.PatientIdentifier
WHERE IdentifierValue LIKE 'DUP%'
  AND IdentifierTypeCode = 'HOSPITAL_NUMBER'
  AND IsCurrent = 1;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Invalid self-merges',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Surviving and superseded patients must be different.'
FROM pas.PatientMerge
WHERE SurvivingPatientId = SupersededPatientId;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Patients appearing in multiple merge events',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'The valid merge baseline uses each patient in only one merge event.'
FROM
(
    SELECT
        MergePatient.PatientId
    FROM
    (
        SELECT SurvivingPatientId AS PatientId
        FROM pas.PatientMerge

        UNION ALL

        SELECT SupersededPatientId AS PatientId
        FROM pas.PatientMerge
    ) AS MergePatient
    GROUP BY
        MergePatient.PatientId
    HAVING COUNT_BIG(*) > 1
) AS RepeatedMergePatient;

INSERT INTO #ValidationResults
SELECT
    'PATIENT_IDENTITY',
    'Duplicate merge message-control identifiers',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'The valid merge baseline must contain unique message-control identifiers.'
FROM
(
    SELECT
        SourceMessageControlId
    FROM pas.PatientMerge
    WHERE SourceMessageControlId IS NOT NULL
    GROUP BY
        SourceMessageControlId
    HAVING COUNT_BIG(*) > 1
) AS DuplicateMergeMessage;

-------------------------------------------------------------------------------
-- 3. PAS activity count reconciliation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Admission row count',
    1600,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 1600 THEN 1 ELSE 0 END,
    'Expected valid admitted-patient spell baseline.'
FROM pas.Admission;

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Consultant episode row count',
    3125,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 3125 THEN 1 ELSE 0 END,
    'Expected valid consultant episode baseline.'
FROM pas.ConsultantEpisode;

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Diagnosis row count',
    7797,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 7797 THEN 1 ELSE 0 END,
    'Expected valid local diagnosis baseline.'
FROM pas.Diagnosis;

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Procedure row count',
    2150,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 2150 THEN 1 ELSE 0 END,
    'Expected valid local procedure baseline.'
FROM pas.[Procedure];

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Ward-stay row count',
    3211,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 3211 THEN 1 ELSE 0 END,
    'Expected valid ward-movement baseline.'
FROM pas.WardStay;

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Open admission count',
    192,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 192 THEN 1 ELSE 0 END,
    'Twelve per cent of the 1,600-admission baseline.'
FROM pas.Admission
WHERE AdmissionStatusCode = 'OPEN';

INSERT INTO #ValidationResults
SELECT
    'ACTIVITY_COUNTS',
    'Discharged admission count',
    1408,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 1408 THEN 1 ELSE 0 END,
    'Closed admitted-patient spells.'
FROM pas.Admission
WHERE AdmissionStatusCode = 'DISCHARGED';

-------------------------------------------------------------------------------
-- 4. Referential-integrity reconciliation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Admissions with unknown patients',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every admission must resolve to pas.Patient.'
FROM pas.Admission AS a
LEFT JOIN pas.Patient AS p
    ON p.PatientId = a.PatientId
WHERE p.PatientId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Admissions with unknown organisations',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every admission organisation must resolve to ref.Organisation.'
FROM pas.Admission AS a
LEFT JOIN ref.Organisation AS o
    ON o.OrganisationId = a.OrganisationId
WHERE o.OrganisationId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Admissions with unknown sites',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every admission site must resolve to ref.Site.'
FROM pas.Admission AS a
LEFT JOIN ref.Site AS s
    ON s.SiteId = a.SiteId
WHERE s.SiteId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Consultant episodes with unknown admissions',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every consultant episode must resolve to pas.Admission.'
FROM pas.ConsultantEpisode AS ce
LEFT JOIN pas.Admission AS a
    ON a.AdmissionId = ce.AdmissionId
WHERE a.AdmissionId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Consultant episodes with unknown consultants',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every consultant episode must resolve to ref.Consultant.'
FROM pas.ConsultantEpisode AS ce
LEFT JOIN ref.Consultant AS c
    ON c.ConsultantId = ce.ConsultantId
WHERE c.ConsultantId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Consultant episodes with unknown main specialties',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Main specialty must resolve to ref.Specialty.'
FROM pas.ConsultantEpisode AS ce
LEFT JOIN ref.Specialty AS s
    ON s.SpecialtyId = ce.MainSpecialtyId
WHERE s.SpecialtyId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Consultant episodes with unknown treatment specialties',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Treatment specialty must resolve to ref.Specialty.'
FROM pas.ConsultantEpisode AS ce
LEFT JOIN ref.Specialty AS s
    ON s.SpecialtyId = ce.TreatmentSpecialtyId
WHERE s.SpecialtyId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Diagnoses with unknown consultant episodes',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every diagnosis must resolve to pas.ConsultantEpisode.'
FROM pas.Diagnosis AS d
LEFT JOIN pas.ConsultantEpisode AS ce
    ON ce.ConsultantEpisodeId = d.ConsultantEpisodeId
WHERE ce.ConsultantEpisodeId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Procedures with unknown consultant episodes',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every procedure must resolve to pas.ConsultantEpisode.'
FROM pas.[Procedure] AS p
LEFT JOIN pas.ConsultantEpisode AS ce
    ON ce.ConsultantEpisodeId = p.ConsultantEpisodeId
WHERE ce.ConsultantEpisodeId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Procedures with unknown consultants',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Procedure consultant must resolve to ref.Consultant.'
FROM pas.[Procedure] AS p
LEFT JOIN ref.Consultant AS c
    ON c.ConsultantId = p.ConsultantId
WHERE c.ConsultantId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Procedures with unknown sites',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Procedure site must resolve to ref.Site.'
FROM pas.[Procedure] AS p
LEFT JOIN ref.Site AS s
    ON s.SiteId = p.SiteId
WHERE s.SiteId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Ward stays with unknown admissions',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every ward stay must resolve to pas.Admission.'
FROM pas.WardStay AS ws
LEFT JOIN pas.Admission AS a
    ON a.AdmissionId = ws.AdmissionId
WHERE a.AdmissionId IS NULL;

INSERT INTO #ValidationResults
SELECT
    'REFERENTIAL_INTEGRITY',
    'Ward stays with unknown wards',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every ward stay must resolve to ref.Ward.'
FROM pas.WardStay AS ws
LEFT JOIN ref.Ward AS w
    ON w.WardId = ws.WardId
WHERE w.WardId IS NULL;

-------------------------------------------------------------------------------
-- 5. Patient and admission operating rules
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'OPERATING_RULES',
    'Admissions assigned to superseded patients',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'New valid activity must not be generated against superseded identities.'
FROM pas.Admission AS a
INNER JOIN pas.PatientMerge AS pm
    ON pm.SupersededPatientId = a.PatientId;

INSERT INTO #ValidationResults
SELECT
    'OPERATING_RULES',
    'Admissions assigned to deceased patients',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'The valid journey baseline excludes deceased patients.'
FROM pas.Admission AS a
INNER JOIN pas.Patient AS p
    ON p.PatientId = a.PatientId
WHERE p.PatientStatusCode = 'DECEASED';

INSERT INTO #ValidationResults
SELECT
    'OPERATING_RULES',
    'Admission discharge-before-admission failures',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'DischargeDateTime must not precede AdmissionDateTime.'
FROM pas.Admission
WHERE DischargeDateTime < AdmissionDateTime;

INSERT INTO #ValidationResults
SELECT
    'OPERATING_RULES',
    'Open admissions containing discharge details',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Open admissions must not contain discharge datetime, method or destination.'
FROM pas.Admission
WHERE AdmissionStatusCode = 'OPEN'
  AND
  (
      DischargeDateTime IS NOT NULL
      OR DischargeMethodCode IS NOT NULL
      OR DischargeDestinationCode IS NOT NULL
  );

INSERT INTO #ValidationResults
SELECT
    'OPERATING_RULES',
    'Discharged admissions missing discharge details',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Discharged admissions require discharge datetime and method.'
FROM pas.Admission
WHERE AdmissionStatusCode = 'DISCHARGED'
  AND
  (
      DischargeDateTime IS NULL
      OR DischargeMethodCode IS NULL
  );

-------------------------------------------------------------------------------
-- 6. Chronology validation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'CHRONOLOGY',
    'Consultant episodes outside admission dates',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Episode dates must remain within the owning admission.'
FROM pas.ConsultantEpisode AS ce
INNER JOIN pas.Admission AS a
    ON a.AdmissionId = ce.AdmissionId
WHERE ce.EpisodeStartDateTime < a.AdmissionDateTime
   OR ce.EpisodeEndDateTime < ce.EpisodeStartDateTime
   OR
   (
       a.DischargeDateTime IS NOT NULL
       AND ce.EpisodeEndDateTime > a.DischargeDateTime
   )
   OR
   (
       a.DischargeDateTime IS NULL
       AND ce.EpisodeStartDateTime > @DataAsAt
   )
   OR
   (
       ce.EpisodeEndDateTime IS NOT NULL
       AND ce.EpisodeEndDateTime > @DataAsAt
   );

INSERT INTO #ValidationResults
SELECT
    'CHRONOLOGY',
    'Diagnoses outside consultant episode dates',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'DiagnosisDate must fall within the owning consultant episode.'
FROM pas.Diagnosis AS d
INNER JOIN pas.ConsultantEpisode AS ce
    ON ce.ConsultantEpisodeId = d.ConsultantEpisodeId
WHERE d.DiagnosisDate < CONVERT(DATE, ce.EpisodeStartDateTime)
   OR d.DiagnosisDate >
      CONVERT
      (
          DATE,
          COALESCE(ce.EpisodeEndDateTime, @DataAsAt)
      );

INSERT INTO #ValidationResults
SELECT
    'CHRONOLOGY',
    'Procedures outside consultant episode dates',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'ProcedureDateTime must fall within the owning consultant episode.'
FROM pas.[Procedure] AS p
INNER JOIN pas.ConsultantEpisode AS ce
    ON ce.ConsultantEpisodeId = p.ConsultantEpisodeId
WHERE p.ProcedureDateTime < ce.EpisodeStartDateTime
   OR p.ProcedureDateTime >
      COALESCE(ce.EpisodeEndDateTime, @DataAsAt);

INSERT INTO #ValidationResults
SELECT
    'CHRONOLOGY',
    'Ward stays outside admission dates',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Ward-stay dates must remain within the owning admission.'
FROM pas.WardStay AS ws
INNER JOIN pas.Admission AS a
    ON a.AdmissionId = ws.AdmissionId
WHERE ws.WardStartDateTime < a.AdmissionDateTime
   OR ws.WardEndDateTime < ws.WardStartDateTime
   OR
   (
       a.DischargeDateTime IS NOT NULL
       AND ws.WardEndDateTime > a.DischargeDateTime
   )
   OR
   (
       a.DischargeDateTime IS NULL
       AND ws.WardStartDateTime > @DataAsAt
   )
   OR
   (
       ws.WardEndDateTime IS NOT NULL
       AND ws.WardEndDateTime > @DataAsAt
   );

INSERT INTO #ValidationResults
SELECT
    'CHRONOLOGY',
    'Consultant episode gaps or overlaps',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Episode boundaries must be contiguous within each admission.'
FROM
(
    SELECT
        AdmissionId,
        EpisodeSequence,
        EpisodeStartDateTime,
        LAG(EpisodeEndDateTime) OVER
        (
            PARTITION BY AdmissionId
            ORDER BY EpisodeSequence
        ) AS PreviousEpisodeEndDateTime
    FROM pas.ConsultantEpisode
) AS EpisodeTimeline
WHERE EpisodeSequence > 1
  AND EpisodeStartDateTime <> PreviousEpisodeEndDateTime;

INSERT INTO #ValidationResults
SELECT
    'CHRONOLOGY',
    'Ward-stay gaps or overlaps',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Ward movements must be contiguous and non-overlapping.'
FROM
(
    SELECT
        AdmissionId,
        WardStaySequence,
        WardStartDateTime,
        LAG(WardEndDateTime) OVER
        (
            PARTITION BY AdmissionId
            ORDER BY WardStaySequence
        ) AS PreviousWardEndDateTime
    FROM pas.WardStay
) AS WardTimeline
WHERE WardStaySequence > 1
  AND WardStartDateTime <> PreviousWardEndDateTime;

-------------------------------------------------------------------------------
-- 7. Sequence and primary-code validation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'SEQUENCING',
    'Admissions with invalid consultant episode sequences',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Episode sequence must begin at one and be contiguous.'
FROM
(
    SELECT
        AdmissionId
    FROM pas.ConsultantEpisode
    GROUP BY
        AdmissionId
    HAVING
        MIN(EpisodeSequence) <> 1
        OR MAX(EpisodeSequence) <> COUNT_BIG(*)
        OR COUNT_BIG(DISTINCT EpisodeSequence) <> COUNT_BIG(*)
) AS InvalidEpisodeSequence;

INSERT INTO #ValidationResults
SELECT
    'SEQUENCING',
    'Episodes with invalid diagnosis sequences',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Diagnosis sequence must begin at one and be contiguous.'
FROM
(
    SELECT
        ConsultantEpisodeId
    FROM pas.Diagnosis
    GROUP BY
        ConsultantEpisodeId
    HAVING
        MIN(DiagnosisSequence) <> 1
        OR MAX(DiagnosisSequence) <> COUNT_BIG(*)
        OR COUNT_BIG(DISTINCT DiagnosisSequence) <> COUNT_BIG(*)
) AS InvalidDiagnosisSequence;

INSERT INTO #ValidationResults
SELECT
    'SEQUENCING',
    'Episodes with invalid procedure sequences',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Procedure sequence must begin at one and be contiguous where present.'
FROM
(
    SELECT
        ConsultantEpisodeId
    FROM pas.[Procedure]
    GROUP BY
        ConsultantEpisodeId
    HAVING
        MIN(ProcedureSequence) <> 1
        OR MAX(ProcedureSequence) <> COUNT_BIG(*)
        OR COUNT_BIG(DISTINCT ProcedureSequence) <> COUNT_BIG(*)
) AS InvalidProcedureSequence;

INSERT INTO #ValidationResults
SELECT
    'SEQUENCING',
    'Admissions with invalid ward-stay sequences',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Ward-stay sequence must begin at one and be contiguous.'
FROM
(
    SELECT
        AdmissionId
    FROM pas.WardStay
    GROUP BY
        AdmissionId
    HAVING
        MIN(WardStaySequence) <> 1
        OR MAX(WardStaySequence) <> COUNT_BIG(*)
        OR COUNT_BIG(DISTINCT WardStaySequence) <> COUNT_BIG(*)
) AS InvalidWardStaySequence;

INSERT INTO #ValidationResults
SELECT
    'PRIMARY_CODES',
    'Episodes without exactly one primary diagnosis',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Every consultant episode must contain exactly one primary diagnosis.'
FROM
(
    SELECT
        ce.ConsultantEpisodeId
    FROM pas.ConsultantEpisode AS ce
    LEFT JOIN pas.Diagnosis AS d
        ON d.ConsultantEpisodeId = ce.ConsultantEpisodeId
    GROUP BY
        ce.ConsultantEpisodeId
    HAVING
        SUM
        (
            CASE
                WHEN d.IsPrimaryDiagnosis = 1 THEN 1
                ELSE 0
            END
        ) <> 1
) AS InvalidPrimaryDiagnosis;

INSERT INTO #ValidationResults
SELECT
    'PRIMARY_CODES',
    'Episodes with procedures but not exactly one primary procedure',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Each episode containing procedures must have one primary procedure.'
FROM
(
    SELECT
        ConsultantEpisodeId
    FROM pas.[Procedure]
    GROUP BY
        ConsultantEpisodeId
    HAVING
        SUM
        (
            CASE
                WHEN IsPrimaryProcedure = 1 THEN 1
                ELSE 0
            END
        ) <> 1
) AS InvalidPrimaryProcedure;

-------------------------------------------------------------------------------
-- 8. Open and closed journey-end validation
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'JOURNEY_END_STATE',
    'Open admissions without one final open consultant episode',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'The final consultant episode for an open admission must remain open.'
FROM
(
    SELECT
        a.AdmissionId,
        ce.EpisodeEndDateTime,
        ce.EpisodeStatusCode,
        ROW_NUMBER() OVER
        (
            PARTITION BY a.AdmissionId
            ORDER BY ce.EpisodeSequence DESC
        ) AS ReverseSequence
    FROM pas.Admission AS a
    INNER JOIN pas.ConsultantEpisode AS ce
        ON ce.AdmissionId = a.AdmissionId
    WHERE a.AdmissionStatusCode = 'OPEN'
) AS OpenAdmissionEpisode
WHERE ReverseSequence = 1
  AND
  (
      EpisodeEndDateTime IS NOT NULL
      OR EpisodeStatusCode <> 'OPEN'
  );

INSERT INTO #ValidationResults
SELECT
    'JOURNEY_END_STATE',
    'Open admissions without one final open ward stay',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'The final ward stay for an open admission must remain open.'
FROM
(
    SELECT
        a.AdmissionId,
        ws.WardEndDateTime,
        ws.WardStayStatusCode,
        ws.DischargeWardFlag,
        ROW_NUMBER() OVER
        (
            PARTITION BY a.AdmissionId
            ORDER BY ws.WardStaySequence DESC
        ) AS ReverseSequence
    FROM pas.Admission AS a
    INNER JOIN pas.WardStay AS ws
        ON ws.AdmissionId = a.AdmissionId
    WHERE a.AdmissionStatusCode = 'OPEN'
) AS OpenAdmissionWard
WHERE ReverseSequence = 1
  AND
  (
      WardEndDateTime IS NOT NULL
      OR WardStayStatusCode <> 'OPEN'
      OR DischargeWardFlag <> 0
  );

INSERT INTO #ValidationResults
SELECT
    'JOURNEY_END_STATE',
    'Admissions without exactly one admission ward',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Each admission must have exactly one admission ward flag.'
FROM
(
    SELECT
        AdmissionId
    FROM pas.WardStay
    GROUP BY
        AdmissionId
    HAVING
        SUM
        (
            CASE
                WHEN AdmissionWardFlag = 1 THEN 1
                ELSE 0
            END
        ) <> 1
) AS InvalidAdmissionWard;

INSERT INTO #ValidationResults
SELECT
    'JOURNEY_END_STATE',
    'Discharged admissions without exactly one discharge ward',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Each discharged admission must have exactly one discharge ward flag.'
FROM
(
    SELECT
        a.AdmissionId
    FROM pas.Admission AS a
    LEFT JOIN pas.WardStay AS ws
        ON ws.AdmissionId = a.AdmissionId
    WHERE a.AdmissionStatusCode = 'DISCHARGED'
    GROUP BY
        a.AdmissionId
    HAVING
        SUM
        (
            CASE
                WHEN ws.DischargeWardFlag = 1 THEN 1
                ELSE 0
            END
        ) <> 1
) AS InvalidDischargeWard;

-------------------------------------------------------------------------------
-- 9. Confirm that controlled defect extracts were not loaded
-------------------------------------------------------------------------------

INSERT INTO #ValidationResults
SELECT
    'DEFECT_ISOLATION',
    'Controlled admission defect rows loaded into Aegis_Source',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Defect AdmissionIds use the reserved 900000 range.'
FROM pas.Admission
WHERE AdmissionId >= 900000
   OR AdmissionNumber LIKE 'DEFADM%';

INSERT INTO #ValidationResults
SELECT
    'DEFECT_ISOLATION',
    'Controlled episode defect rows loaded into Aegis_Source',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Defect ConsultantEpisodeIds use the reserved 910000 range.'
FROM pas.ConsultantEpisode
WHERE ConsultantEpisodeId >= 910000
   OR EpisodeNumber LIKE 'DEFEPI%';

INSERT INTO #ValidationResults
SELECT
    'DEFECT_ISOLATION',
    'Controlled diagnosis defect rows loaded into Aegis_Source',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Defect DiagnosisIds use the reserved 920000 range.'
FROM pas.Diagnosis
WHERE DiagnosisId >= 920000
   OR SourceDiagnosisId LIKE 'DEF-DIAG%';

INSERT INTO #ValidationResults
SELECT
    'DEFECT_ISOLATION',
    'Controlled procedure defect rows loaded into Aegis_Source',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Defect ProcedureIds use the reserved 930000 range.'
FROM pas.[Procedure]
WHERE ProcedureId >= 930000
   OR SourceProcedureId LIKE 'DEF-PROC%';

INSERT INTO #ValidationResults
SELECT
    'DEFECT_ISOLATION',
    'Controlled ward-stay defect rows loaded into Aegis_Source',
    0,
    COUNT_BIG(*),
    CASE WHEN COUNT_BIG(*) = 0 THEN 1 ELSE 0 END,
    'Defect WardStayIds use the reserved 940000 range.'
FROM pas.WardStay
WHERE WardStayId >= 940000
   OR SourceWardStayId LIKE 'DEF-WARD%';

-------------------------------------------------------------------------------
-- 10. Detailed validation output
-------------------------------------------------------------------------------

SELECT
    CheckId,
    CheckCategory,
    CheckName,
    ExpectedValue,
    ActualValue,
    Passed,
    Detail
FROM #ValidationResults
ORDER BY
    CheckId;

-------------------------------------------------------------------------------
-- 11. Summary output
-------------------------------------------------------------------------------

SELECT
    COUNT_BIG(*) AS TotalChecks,
    SUM
    (
        CASE
            WHEN Passed = 1 THEN 1
            ELSE 0
        END
    ) AS PassedChecks,
    SUM
    (
        CASE
            WHEN Passed = 0 THEN 1
            ELSE 0
        END
    ) AS FailedChecks
FROM #ValidationResults;

-------------------------------------------------------------------------------
-- 12. Expected external Day 3 SSIS defect-pack reconciliation
--
-- These files are deliberately outside Aegis_Source. The values below are
-- documented controls for the future SSIS batch audit and quarantine process.
-------------------------------------------------------------------------------

SELECT
    DefectFile,
    ExpectedRows,
    ExpectedScenarios,
    ExpectedOutcome
FROM
(
    VALUES
        (
            'admission_defects.csv',
            CAST(5 AS INT),
            CAST(5 AS INT),
            'QUARANTINE'
        ),
        (
            'consultant_episode_defects.csv',
            4,
            4,
            'QUARANTINE'
        ),
        (
            'diagnosis_defects.csv',
            4,
            3,
            'QUARANTINE'
        ),
        (
            'procedure_defects.csv',
            2,
            2,
            'QUARANTINE'
        ),
        (
            'ward_stay_defects.csv',
            2,
            1,
            'QUARANTINE'
        ),
        (
            'TOTAL',
            17,
            15,
            'QUARANTINE'
        )
) AS ExpectedDefectPack
(
    DefectFile,
    ExpectedRows,
    ExpectedScenarios,
    ExpectedOutcome
);

-------------------------------------------------------------------------------
-- 13. Fail the execution when any loaded-source control fails
-------------------------------------------------------------------------------

DECLARE @FailedCheckCount BIGINT =
(
    SELECT COUNT_BIG(*)
    FROM #ValidationResults
    WHERE Passed = 0
);

IF @FailedCheckCount > 0
BEGIN
    DECLARE @FailureMessage NVARCHAR(2048) =
        CONCAT
        (
            'Aegis Day 2 source validation failed. ',
            @FailedCheckCount,
            ' check(s) did not pass.'
        );

    THROW 51000, @FailureMessage, 1;
END;

PRINT
(
    'Aegis Day 2 source-data validation and reconciliation passed. '
    + 'All loaded-source checks succeeded.'
);
GO