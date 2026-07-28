/*
    Aegis Day 3 control-plane validation

    Validates:
    - Aegis_Audit and Aegis_Staging databases
    - audit, dq, replay, landing, stg, curated and quarantine schemas
    - foundational audit and staging tables
    - required control-plane columns
    - primary operational relationships
    - important supporting indexes
    - governed interface and validation-rule seed records
    - retained failed-execution audit history
    - no orphaned active audit executions
    - latest successful valid admission baseline
    - latest successful controlled defect extract
    - latest successful realistic mixed admission batch
    - source, landing, staging, curated, outcome, exception and quarantine reconciliation

    Expected result:
    - 78 checks passed
    - 0 checks failed
*/

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
BEGIN
    DROP TABLE #ValidationResults;
END;

CREATE TABLE #ValidationResults
(
    [CheckNumber]  INT IDENTITY (1, 1) NOT NULL,
    [CheckName]    NVARCHAR(300)       NOT NULL,
    [Passed]       BIT                 NOT NULL,
    [ActualResult] NVARCHAR(1000)      NULL
);

/*
    Database checks
*/

INSERT INTO #ValidationResults
(
    [CheckName],
    [Passed],
    [ActualResult]
)
SELECT
    N'Aegis_Audit database exists',
    CASE
        WHEN DB_ID(N'Aegis_Audit') IS NOT NULL THEN 1
        ELSE 0
    END,
    COALESCE
    (
        CONVERT(NVARCHAR(20), DB_ID(N'Aegis_Audit')),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
(
    [CheckName],
    [Passed],
    [ActualResult]
)
SELECT
    N'Aegis_Staging database exists',
    CASE
        WHEN DB_ID(N'Aegis_Staging') IS NOT NULL THEN 1
        ELSE 0
    END,
    COALESCE
    (
        CONVERT(NVARCHAR(20), DB_ID(N'Aegis_Staging')),
        N'NOT FOUND'
    );

/*
    Schema checks
*/

INSERT INTO #ValidationResults
SELECT
    N'Aegis_Audit contains audit schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[sys].[schemas]
            WHERE [name] = N'audit'
        )
        THEN 1
        ELSE 0
    END,
    N'audit';

INSERT INTO #ValidationResults
SELECT
    N'Aegis_Audit contains dq schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[sys].[schemas]
            WHERE [name] = N'dq'
        )
        THEN 1
        ELSE 0
    END,
    N'dq';

INSERT INTO #ValidationResults
SELECT
    N'Aegis_Audit contains replay schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[sys].[schemas]
            WHERE [name] = N'replay'
        )
        THEN 1
        ELSE 0
    END,
    N'replay';

INSERT INTO #ValidationResults
SELECT
    N'Aegis_Staging contains landing schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Staging].[sys].[schemas]
            WHERE [name] = N'landing'
        )
        THEN 1
        ELSE 0
    END,
    N'landing';

INSERT INTO #ValidationResults
SELECT
    N'Aegis_Staging contains stg schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Staging].[sys].[schemas]
            WHERE [name] = N'stg'
        )
        THEN 1
        ELSE 0
    END,
    N'stg';

INSERT INTO #ValidationResults
SELECT
    N'Aegis_Staging contains quarantine schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Staging].[sys].[schemas]
            WHERE [name] = N'quarantine'
        )
        THEN 1
        ELSE 0
    END,
    N'quarantine';


INSERT INTO #ValidationResults
SELECT
    N'Aegis_Staging contains curated schema',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Staging].[sys].[schemas]
            WHERE [name] = N'curated'
        )
        THEN 1
        ELSE 0
    END,
    N'curated';

/*
    Audit table checks
*/

INSERT INTO #ValidationResults
SELECT
    N'audit.Interface exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[audit].[Interface]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'audit.Interface';

INSERT INTO #ValidationResults
SELECT
    N'audit.Batch exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[audit].[Batch]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'audit.Batch';

INSERT INTO #ValidationResults
SELECT
    N'audit.PackageExecution exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[audit].[PackageExecution]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'audit.PackageExecution';

INSERT INTO #ValidationResults
SELECT
    N'audit.RecordOutcome exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[audit].[RecordOutcome]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'audit.RecordOutcome';

INSERT INTO #ValidationResults
SELECT
    N'dq.ValidationRule exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[dq].[ValidationRule]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'dq.ValidationRule';

INSERT INTO #ValidationResults
SELECT
    N'dq.DataQualityException exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[dq].[DataQualityException]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'dq.DataQualityException';

INSERT INTO #ValidationResults
SELECT
    N'replay.ReplayRequest exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[replay].[ReplayRequest]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'replay.ReplayRequest';

INSERT INTO #ValidationResults
SELECT
    N'replay.ReplayAttempt exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Audit].[replay].[ReplayAttempt]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'replay.ReplayAttempt';

/*
    Staging table checks
*/

INSERT INTO #ValidationResults
SELECT
    N'landing.Admission exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Staging].[landing].[Admission]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'landing.Admission';

INSERT INTO #ValidationResults
SELECT
    N'stg.Admission exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Staging].[stg].[Admission]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'stg.Admission';

INSERT INTO #ValidationResults
SELECT
    N'quarantine.Admission exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Staging].[quarantine].[Admission]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'quarantine.Admission';


INSERT INTO #ValidationResults
SELECT
    N'curated.Admission exists',
    CASE
        WHEN OBJECT_ID
        (
            N'[Aegis_Staging].[curated].[Admission]',
            N'U'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'curated.Admission';

/*
    Key column checks
*/

INSERT INTO #ValidationResults
SELECT
    N'audit.Batch contains BatchReference',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Audit.audit.Batch',
            N'BatchReference'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'BatchReference';

INSERT INTO #ValidationResults
SELECT
    N'audit.Batch contains reconciliation counts',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Audit.audit.Batch',
            N'SourceRowCount'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Audit.audit.Batch',
            N'LandedRowCount'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Audit.audit.Batch',
            N'AcceptedRowCount'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Audit.audit.Batch',
            N'RejectedRowCount'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Audit.audit.Batch',
            N'QuarantinedRowCount'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'Source, landed, accepted, rejected and quarantined counts';

INSERT INTO #ValidationResults
SELECT
    N'audit.PackageExecution contains SsisExecutionId',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Audit.audit.PackageExecution',
            N'SsisExecutionId'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'SsisExecutionId';

INSERT INTO #ValidationResults
SELECT
    N'audit.RecordOutcome contains principal processing outcome',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Audit.audit.RecordOutcome',
            N'ProcessingOutcome'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'ProcessingOutcome';

INSERT INTO #ValidationResults
SELECT
    N'dq.ValidationRule contains version and expected outcome',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Audit.dq.ValidationRule',
            N'ValidationRuleVersion'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Audit.dq.ValidationRule',
            N'ExpectedOutcome'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'ValidationRuleVersion and ExpectedOutcome';

INSERT INTO #ValidationResults
SELECT
    N'dq.DataQualityException contains resolution workflow',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Audit.dq.DataQualityException',
            N'ResolutionStatus'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Audit.dq.DataQualityException',
            N'ResolvedAt'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'ResolutionStatus and ResolvedAt';

INSERT INTO #ValidationResults
SELECT
    N'landing.Admission contains ingestion provenance',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Staging.landing.Admission',
            N'BatchId'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.landing.Admission',
            N'PackageExecutionId'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.landing.Admission',
            N'SourceRowNumber'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.landing.Admission',
            N'LandedAt'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'Batch, package, row and landing provenance';

INSERT INTO #ValidationResults
SELECT
    N'stg.Admission contains lookup classifications',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Staging.stg.Admission',
            N'PatientLookupStatus'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.stg.Admission',
            N'OrganisationLookupStatus'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.stg.Admission',
            N'SiteLookupStatus'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'Patient, organisation and site lookup statuses';

INSERT INTO #ValidationResults
SELECT
    N'quarantine.Admission contains correction and replay fields',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Staging.quarantine.Admission',
            N'CorrectedPayload'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.quarantine.Admission',
            N'ReplayRequestReference'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.quarantine.Admission',
            N'ReplayedAt'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'Correction and replay metadata';


INSERT INTO #ValidationResults
SELECT
    N'curated.Admission contains lineage and acceptance fields',
    CASE
        WHEN COL_LENGTH
        (
            N'Aegis_Staging.curated.Admission',
            N'StagingAdmissionId'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.curated.Admission',
            N'BatchId'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.curated.Admission',
            N'PackageExecutionId'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.curated.Admission',
            N'AcceptedAt'
        ) IS NOT NULL
         AND COL_LENGTH
        (
            N'Aegis_Staging.curated.Admission',
            N'CuratedAt'
        ) IS NOT NULL
        THEN 1
        ELSE 0
    END,
    N'Staging, batch, package, acceptance and curation lineage';

/*
    Relationship checks
*/

INSERT INTO #ValidationResults
SELECT
    N'audit.Batch references audit.Interface',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[sys].[foreign_keys]
            WHERE [name] = N'FK_audit_Batch_Interface'
        )
        THEN 1
        ELSE 0
    END,
    N'FK_audit_Batch_Interface';

INSERT INTO #ValidationResults
SELECT
    N'audit.PackageExecution references audit.Batch',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[sys].[foreign_keys]
            WHERE [name] =
                N'FK_audit_PackageExecution_Batch'
        )
        THEN 1
        ELSE 0
    END,
    N'FK_audit_PackageExecution_Batch';

INSERT INTO #ValidationResults
SELECT
    N'audit.RecordOutcome references batch and package execution',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[sys].[foreign_keys]
            WHERE [name] IN
            (
                N'FK_audit_RecordOutcome_Batch',
                N'FK_audit_RecordOutcome_PackageExecution'
            )
        ) = 2
        THEN 1
        ELSE 0
    END,
    N'2 expected foreign keys';

INSERT INTO #ValidationResults
SELECT
    N'dq.DataQualityException has four audit relationships',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[sys].[foreign_keys]
            WHERE [name] IN
            (
                N'FK_dq_DataQualityException_RecordOutcome',
                N'FK_dq_DataQualityException_Batch',
                N'FK_dq_DataQualityException_PackageExecution',
                N'FK_dq_DataQualityException_ValidationRule'
            )
        ) = 4
        THEN 1
        ELSE 0
    END,
    N'4 expected foreign keys';

INSERT INTO #ValidationResults
SELECT
    N'stg.Admission references landing.Admission',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Staging].[sys].[foreign_keys]
            WHERE [name] =
                N'FK_stg_Admission_LandingAdmission'
        )
        THEN 1
        ELSE 0
    END,
    N'FK_stg_Admission_LandingAdmission';

INSERT INTO #ValidationResults
SELECT
    N'quarantine.Admission references landing and staging',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[sys].[foreign_keys]
            WHERE [name] IN
            (
                N'FK_quarantine_Admission_LandingAdmission',
                N'FK_quarantine_Admission_StagingAdmission'
            )
        ) = 2
        THEN 1
        ELSE 0
    END,
    N'2 expected foreign keys';


INSERT INTO #ValidationResults
SELECT
    N'curated.Admission references stg.Admission',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Staging].[sys].[foreign_keys]
            WHERE [name] =
                N'FK_curated_Admission_StagingAdmission'
        )
        THEN 1
        ELSE 0
    END,
    N'FK_curated_Admission_StagingAdmission';

/*
    Important index checks
*/

INSERT INTO #ValidationResults
SELECT
    N'audit.Batch operational indexes exist',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[sys].[indexes]
            WHERE [name] IN
            (
                N'IX_audit_Batch_InterfaceId_ReceivedAt',
                N'IX_audit_Batch_BatchStatus',
                N'IX_audit_Batch_ParentBatchId'
            )
        ) = 3
        THEN 1
        ELSE 0
    END,
    N'3 expected indexes';

INSERT INTO #ValidationResults
SELECT
    N'landing.Admission operational indexes exist',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[sys].[indexes]
            WHERE [name] IN
            (
                N'IX_landing_Admission_BatchId',
                N'IX_landing_Admission_PackageExecutionId',
                N'IX_landing_Admission_SourceRecordIdentifier',
                N'IX_landing_Admission_AdmissionNumber'
            )
        ) = 4
        THEN 1
        ELSE 0
    END,
    N'4 expected indexes';

INSERT INTO #ValidationResults
SELECT
    N'stg.Admission operational indexes exist',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[sys].[indexes]
            WHERE [name] IN
            (
                N'IX_stg_Admission_BatchId_ProcessingOutcome',
                N'IX_stg_Admission_PackageExecutionId',
                N'IX_stg_Admission_AdmissionId',
                N'IX_stg_Admission_PatientId'
            )
        ) = 4
        THEN 1
        ELSE 0
    END,
    N'4 expected indexes';

INSERT INTO #ValidationResults
SELECT
    N'quarantine.Admission operational indexes exist',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[sys].[indexes]
            WHERE [name] IN
            (
                N'IX_quarantine_Admission_BatchId',
                N'IX_quarantine_Admission_PackageExecutionId',
                N'IX_quarantine_Admission_QuarantineStatus',
                N'IX_quarantine_Admission_SourceRecordIdentifier',
                N'IX_quarantine_Admission_ReplayRequestReference'
            )
        ) = 5
        THEN 1
        ELSE 0
    END,
    N'5 expected indexes';

/*
    Seed checks
*/

INSERT INTO #ValidationResults
SELECT
    N'PAS admission interface seed exists exactly once',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[Interface]
            WHERE [InterfaceCode] =
                'PAS_ADMISSION_EXTRACT'
        ) = 1
        THEN 1
        ELSE 0
    END,
    CONVERT
    (
        NVARCHAR(30),
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[Interface]
            WHERE [InterfaceCode] =
                'PAS_ADMISSION_EXTRACT'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Five admission validation rules exist',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[ValidationRule]
            WHERE [ValidationRuleCode] IN
            (
                'DQ-ADM-001',
                'DQ-ADM-002',
                'DQ-ADM-003',
                'DQ-ADM-004',
                'DQ-ADM-005'
            )
              AND [ValidationRuleVersion] = 1
        ) = 5
        THEN 1
        ELSE 0
    END,
    CONVERT
    (
        NVARCHAR(30),
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[ValidationRule]
            WHERE [ValidationRuleCode] IN
            (
                'DQ-ADM-001',
                'DQ-ADM-002',
                'DQ-ADM-003',
                'DQ-ADM-004',
                'DQ-ADM-005'
            )
              AND [ValidationRuleVersion] = 1
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Admission validation rules all quarantine',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[ValidationRule]
            WHERE [ValidationRuleCode] IN
            (
                'DQ-ADM-001',
                'DQ-ADM-002',
                'DQ-ADM-003',
                'DQ-ADM-004',
                'DQ-ADM-005'
            )
              AND [ValidationRuleVersion] = 1
              AND [ExpectedOutcome] = 'QUARANTINED'
        ) = 5
        THEN 1
        ELSE 0
    END,
    N'Expected 5 QUARANTINED rules';

/*
    Operational-history checks
*/

INSERT INTO #ValidationResults
SELECT
    N'Failed SSIS attempts remain retained in audit history',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchStatus] = 'FAILED'
        )
         AND EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [ExecutionStatus] = 'FAILED'
        )
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Failed batches=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchStatus] = 'FAILED'
        ),
        N'; Failed package executions=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [ExecutionStatus] = 'FAILED'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'No batch or package execution remains active',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[Batch]
                  WHERE [BatchStatus] IN
                  (
                      'RECEIVED',
                      'PROCESSING'
                  )
              ) = 0
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[PackageExecution]
                  WHERE [ExecutionStatus] = 'STARTED'
              ) = 0
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Active batches=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchStatus] IN
            (
                'RECEIVED',
                'PROCESSING'
            )
        ),
        N'; Active package executions=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [ExecutionStatus] = 'STARTED'
        )
    );

/*
    Identify latest successful valid, controlled-defect and mixed batches
*/

DECLARE @LatestValidBatchId BIGINT;
DECLARE @LatestValidPackageExecutionId BIGINT;
DECLARE @LatestDefectBatchId BIGINT;
DECLARE @LatestDefectPackageExecutionId BIGINT;
DECLARE @LatestMixedBatchId BIGINT;
DECLARE @LatestMixedPackageExecutionId BIGINT;

SELECT TOP (1)
    @LatestValidBatchId = [Batch].[BatchId],
    @LatestValidPackageExecutionId =
        [Execution].[PackageExecutionId]
FROM [Aegis_Audit].[audit].[Batch] AS [Batch]
INNER JOIN [Aegis_Audit].[audit].[PackageExecution] AS [Execution]
    ON [Execution].[BatchId] = [Batch].[BatchId]
WHERE [Batch].[BatchStatus] = 'COMPLETED'
  AND [Execution].[ExecutionStatus] = 'SUCCEEDED'
  AND [Execution].[PackageName] =
        N'PKG_Load_Admissions.dtsx'
ORDER BY
    [Batch].[BatchId] DESC,
    [Execution].[PackageExecutionId] DESC;

SELECT TOP (1)
    @LatestDefectBatchId = [Batch].[BatchId],
    @LatestDefectPackageExecutionId =
        [Execution].[PackageExecutionId]
FROM [Aegis_Audit].[audit].[Batch] AS [Batch]
INNER JOIN [Aegis_Audit].[audit].[PackageExecution] AS [Execution]
    ON [Execution].[BatchId] = [Batch].[BatchId]
WHERE [Batch].[BatchStatus] =
        'COMPLETED_WITH_EXCEPTIONS'
  AND [Execution].[ExecutionStatus] =
        'SUCCEEDED_WITH_EXCEPTIONS'
  AND [Execution].[PackageName] =
        N'PKG_Load_Admission_Defects.dtsx'
ORDER BY
    [Batch].[BatchId] DESC,
    [Execution].[PackageExecutionId] DESC;


SELECT TOP (1)
    @LatestMixedBatchId = [Batch].[BatchId],
    @LatestMixedPackageExecutionId =
        [Execution].[PackageExecutionId]
FROM [Aegis_Audit].[audit].[Batch] AS [Batch]
INNER JOIN [Aegis_Audit].[audit].[PackageExecution] AS [Execution]
    ON [Execution].[BatchId] = [Batch].[BatchId]
WHERE [Batch].[BatchStatus] =
        'COMPLETED_WITH_EXCEPTIONS'
  AND [Execution].[ExecutionStatus] =
        'SUCCEEDED_WITH_EXCEPTIONS'
  AND [Execution].[PackageName] =
        N'PKG_Load_Admission_Mixed.dtsx'
ORDER BY
    [Batch].[BatchId] DESC,
    [Execution].[PackageExecutionId] DESC;

/*
    Valid-baseline checks
*/

INSERT INTO #ValidationResults
SELECT
    N'Latest successful valid admission batch exists',
    CASE
        WHEN @LatestValidBatchId IS NOT NULL
         AND @LatestValidPackageExecutionId IS NOT NULL
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'BatchId=',
        COALESCE
        (
            CONVERT(NVARCHAR(30), @LatestValidBatchId),
            N'NULL'
        ),
        N'; PackageExecutionId=',
        COALESCE
        (
            CONVERT
            (
                NVARCHAR(30),
                @LatestValidPackageExecutionId
            ),
            N'NULL'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest valid batch completed successfully',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestValidBatchId
              AND [BatchStatus] = 'COMPLETED'
              AND [ErrorCode] IS NULL
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    [BatchStatus],
                    N'; ErrorCode=',
                    COALESCE([ErrorCode], N'NULL')
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestValidBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest valid package execution succeeded',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [PackageExecutionId] =
                    @LatestValidPackageExecutionId
              AND [BatchId] = @LatestValidBatchId
              AND [ExecutionStatus] = 'SUCCEEDED'
              AND [ErrorCode] IS NULL
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    [ExecutionStatus],
                    N'; ErrorCode=',
                    COALESCE([ErrorCode], N'NULL')
                )
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [PackageExecutionId] =
                    @LatestValidPackageExecutionId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest valid batch reconciles 1600 source and landed rows',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestValidBatchId
              AND [SourceRowCount] = 1600
              AND [LandedRowCount] = 1600
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    N'Source=',
                    COALESCE
                    (
                        CONVERT
                        (
                            NVARCHAR(30),
                            [SourceRowCount]
                        ),
                        N'NULL'
                    ),
                    N'; Landed=',
                    COALESCE
                    (
                        CONVERT
                        (
                            NVARCHAR(30),
                            [LandedRowCount]
                        ),
                        N'NULL'
                    )
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestValidBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest valid batch accepted all 1600 rows',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestValidBatchId
              AND [AcceptedRowCount] = 1600
              AND [RejectedRowCount] = 0
              AND [QuarantinedRowCount] = 0
              AND [WarningRowCount] = 0
              AND [DuplicateRowCount] = 0
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    N'Accepted=',
                    [AcceptedRowCount],
                    N'; Rejected=',
                    [RejectedRowCount],
                    N'; Quarantined=',
                    [QuarantinedRowCount],
                    N'; Warning=',
                    [WarningRowCount],
                    N'; Duplicate=',
                    [DuplicateRowCount]
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestValidBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest valid batch has 1600 landing, staging and outcome rows',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[landing].[Admission]
                  WHERE [BatchId] = @LatestValidBatchId
                    AND [PackageExecutionId] =
                        @LatestValidPackageExecutionId
              ) = 1600
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[stg].[Admission]
                  WHERE [BatchId] = @LatestValidBatchId
                    AND [PackageExecutionId] =
                        @LatestValidPackageExecutionId
              ) = 1600
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestValidBatchId
                    AND [PackageExecutionId] =
                        @LatestValidPackageExecutionId
              ) = 1600
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Landing=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[landing].[Admission]
            WHERE [BatchId] = @LatestValidBatchId
              AND [PackageExecutionId] =
                    @LatestValidPackageExecutionId
        ),
        N'; Staging=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[stg].[Admission]
            WHERE [BatchId] = @LatestValidBatchId
              AND [PackageExecutionId] =
                    @LatestValidPackageExecutionId
        ),
        N'; Outcomes=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestValidBatchId
              AND [PackageExecutionId] =
                    @LatestValidPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest valid batch has no DQ exceptions or quarantine rows',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[dq].[DataQualityException]
                  WHERE [BatchId] = @LatestValidBatchId
                    AND [PackageExecutionId] =
                        @LatestValidPackageExecutionId
              ) = 0
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[quarantine].[Admission]
                  WHERE [BatchId] = @LatestValidBatchId
                    AND [PackageExecutionId] =
                        @LatestValidPackageExecutionId
              ) = 0
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Exceptions=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[DataQualityException]
            WHERE [BatchId] = @LatestValidBatchId
              AND [PackageExecutionId] =
                    @LatestValidPackageExecutionId
        ),
        N'; Quarantine=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[quarantine].[Admission]
            WHERE [BatchId] = @LatestValidBatchId
              AND [PackageExecutionId] =
                    @LatestValidPackageExecutionId
        )
    );

/*
    Controlled-defect checks
*/

INSERT INTO #ValidationResults
SELECT
    N'Latest successful controlled defect batch exists',
    CASE
        WHEN @LatestDefectBatchId IS NOT NULL
         AND @LatestDefectPackageExecutionId IS NOT NULL
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'BatchId=',
        COALESCE
        (
            CONVERT(NVARCHAR(30), @LatestDefectBatchId),
            N'NULL'
        ),
        N'; PackageExecutionId=',
        COALESCE
        (
            CONVERT
            (
                NVARCHAR(30),
                @LatestDefectPackageExecutionId
            ),
            N'NULL'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch records controlled source filename',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [SourceFileName] =
                    N'admission_defects.csv'
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT [SourceFileName]
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch completed with exceptions',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [BatchStatus] =
                    'COMPLETED_WITH_EXCEPTIONS'
              AND [ErrorCode] IS NULL
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    [BatchStatus],
                    N'; ErrorCode=',
                    COALESCE([ErrorCode], N'NULL')
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect package succeeded with exceptions',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
              AND [BatchId] = @LatestDefectBatchId
              AND [ExecutionStatus] =
                    'SUCCEEDED_WITH_EXCEPTIONS'
              AND [ErrorCode] IS NULL
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    [ExecutionStatus],
                    N'; ErrorCode=',
                    COALESCE([ErrorCode], N'NULL')
                )
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch reconciles five source and landed rows',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [SourceRowCount] = 5
              AND [LandedRowCount] = 5
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    N'Source=',
                    [SourceRowCount],
                    N'; Landed=',
                    [LandedRowCount]
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch quarantined all five rows',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [AcceptedRowCount] = 0
              AND [RejectedRowCount] = 0
              AND [QuarantinedRowCount] = 5
              AND [WarningRowCount] = 0
              AND [DuplicateRowCount] = 0
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    N'Accepted=',
                    [AcceptedRowCount],
                    N'; Rejected=',
                    [RejectedRowCount],
                    N'; Quarantined=',
                    [QuarantinedRowCount],
                    N'; Warning=',
                    [WarningRowCount],
                    N'; Duplicate=',
                    [DuplicateRowCount]
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestDefectBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch has five landing, staging, outcome and quarantine rows',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[landing].[Admission]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
              ) = 5
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[stg].[Admission]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
              ) = 5
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
              ) = 5
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[quarantine].[Admission]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
              ) = 5
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Landing=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[landing].[Admission]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        ),
        N'; Staging=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[stg].[Admission]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        ),
        N'; Outcomes=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        ),
        N'; Quarantine=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[quarantine].[Admission]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch contains five DQ exceptions',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[DataQualityException]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        ) = 5
        THEN 1
        ELSE 0
    END,
    CONVERT
    (
        NVARCHAR(30),
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[DataQualityException]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch contains one exception for each admission rule',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT
                    [Rule].[ValidationRuleCode]
                FROM [Aegis_Audit].[dq].[DataQualityException]
                    AS [Exception]
                INNER JOIN [Aegis_Audit].[dq].[ValidationRule]
                    AS [Rule]
                    ON [Rule].[ValidationRuleId] =
                        [Exception].[ValidationRuleId]
                WHERE [Exception].[BatchId] =
                        @LatestDefectBatchId
                  AND [Exception].[PackageExecutionId] =
                        @LatestDefectPackageExecutionId
                  AND [Rule].[ValidationRuleCode] IN
                  (
                      'DQ-ADM-001',
                      'DQ-ADM-002',
                      'DQ-ADM-003',
                      'DQ-ADM-004',
                      'DQ-ADM-005'
                  )
                GROUP BY
                    [Rule].[ValidationRuleCode]
                HAVING COUNT_BIG(*) = 1
            ) AS [RuleCounts]
        ) = 5
        THEN 1
        ELSE 0
    END,
    N'Expected DQ-ADM-001 through DQ-ADM-005 exactly once';

INSERT INTO #ValidationResults
SELECT
    N'Latest defect batch principal outcomes are all quarantined',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
                    AND [ProcessingOutcome] =
                        'QUARANTINED'
              ) = 5
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
                    AND [ProcessingOutcome] <>
                        'QUARANTINED'
              ) = 0
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Quarantined=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
              AND [ProcessingOutcome] =
                    'QUARANTINED'
        ),
        N'; Other outcomes=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
              AND [ProcessingOutcome] <>
                    'QUARANTINED'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest defect landing rows retain file provenance',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[landing].[Admission]
                  WHERE [BatchId] = @LatestDefectBatchId
                    AND [PackageExecutionId] =
                        @LatestDefectPackageExecutionId
                    AND [SourceSystemCode] =
                        'LEGACY_PAS_DEFECT_FILE'
                    AND [SourceFileName] =
                        N'admission_defects.csv'
              ) = 5
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Rows with expected provenance=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[landing].[Admission]
            WHERE [BatchId] = @LatestDefectBatchId
              AND [PackageExecutionId] =
                    @LatestDefectPackageExecutionId
              AND [SourceSystemCode] =
                    'LEGACY_PAS_DEFECT_FILE'
              AND [SourceFileName] =
                    N'admission_defects.csv'
        )
    );


/*
    Mixed-batch and curated-layer checks
*/

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed admission batch exists',
    CASE
        WHEN @LatestMixedBatchId IS NOT NULL
         AND @LatestMixedPackageExecutionId IS NOT NULL
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'BatchId=',
        COALESCE(CONVERT(NVARCHAR(30), @LatestMixedBatchId), N'NULL'),
        N'; PackageExecutionId=',
        COALESCE
        (
            CONVERT
            (
                NVARCHAR(30),
                @LatestMixedPackageExecutionId
            ),
            N'NULL'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch completed with exceptions',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [BatchStatus] =
                    'COMPLETED_WITH_EXCEPTIONS'
              AND [ErrorCode] IS NULL
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    [BatchStatus],
                    N'; ErrorCode=',
                    COALESCE([ErrorCode], N'NULL')
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestMixedBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed package succeeded with exceptions',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
              AND [BatchId] = @LatestMixedBatchId
              AND [PackageName] =
                    N'PKG_Load_Admission_Mixed.dtsx'
              AND [ExecutionStatus] =
                    'SUCCEEDED_WITH_EXCEPTIONS'
              AND [ErrorCode] IS NULL
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    [ExecutionStatus],
                    N'; ErrorCode=',
                    COALESCE([ErrorCode], N'NULL')
                )
            FROM [Aegis_Audit].[audit].[PackageExecution]
            WHERE [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch reconciles 1605 source and landed rows',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [SourceRowCount] = 1605
              AND [LandedRowCount] = 1605
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    N'Source=',
                    [SourceRowCount],
                    N'; Landed=',
                    [LandedRowCount]
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestMixedBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch classifies 1600 accepted and 5 quarantined rows',
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [AcceptedRowCount] = 1600
              AND [RejectedRowCount] = 0
              AND [QuarantinedRowCount] = 5
              AND [WarningRowCount] = 0
              AND [DuplicateRowCount] = 0
        )
        THEN 1
        ELSE 0
    END,
    COALESCE
    (
        (
            SELECT
                CONCAT
                (
                    N'Accepted=',
                    [AcceptedRowCount],
                    N'; Rejected=',
                    [RejectedRowCount],
                    N'; Quarantined=',
                    [QuarantinedRowCount],
                    N'; Warning=',
                    [WarningRowCount],
                    N'; Duplicate=',
                    [DuplicateRowCount]
                )
            FROM [Aegis_Audit].[audit].[Batch]
            WHERE [BatchId] = @LatestMixedBatchId
        ),
        N'NOT FOUND'
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch has 1605 landing, staging and outcome rows',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[landing].[Admission]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
              ) = 1605
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[stg].[Admission]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
              ) = 1605
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
              ) = 1605
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Landing=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[landing].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ),
        N'; Staging=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[stg].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ),
        N'; Outcomes=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch materialises 1600 curated admissions',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[curated].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ) = 1600
        THEN 1
        ELSE 0
    END,
    CONVERT
    (
        NVARCHAR(30),
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[curated].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch materialises 5 quarantined admissions',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[quarantine].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ) = 5
        THEN 1
        ELSE 0
    END,
    CONVERT
    (
        NVARCHAR(30),
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[quarantine].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed curated and quarantine rows reconcile to staging',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[curated].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
        +
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[quarantine].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
        =
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[stg].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Curated=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[curated].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ),
        N'; Quarantine=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[quarantine].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ),
        N'; Staging=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[stg].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch contains five DQ exceptions',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[DataQualityException]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        ) = 5
        THEN 1
        ELSE 0
    END,
    CONVERT
    (
        NVARCHAR(30),
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[dq].[DataQualityException]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch contains one exception for each admission rule',
    CASE
        WHEN
        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT
                    [Rule].[ValidationRuleCode]
                FROM [Aegis_Audit].[dq].[DataQualityException]
                    AS [Exception]
                INNER JOIN [Aegis_Audit].[dq].[ValidationRule]
                    AS [Rule]
                    ON [Rule].[ValidationRuleId] =
                        [Exception].[ValidationRuleId]
                WHERE [Exception].[BatchId] =
                        @LatestMixedBatchId
                  AND [Exception].[PackageExecutionId] =
                        @LatestMixedPackageExecutionId
                  AND [Rule].[ValidationRuleCode] IN
                  (
                      'DQ-ADM-001',
                      'DQ-ADM-002',
                      'DQ-ADM-003',
                      'DQ-ADM-004',
                      'DQ-ADM-005'
                  )
                GROUP BY
                    [Rule].[ValidationRuleCode]
                HAVING COUNT_BIG(*) = 1
            ) AS [RuleCounts]
        ) = 5
        THEN 1
        ELSE 0
    END,
    N'Expected DQ-ADM-001 through DQ-ADM-005 exactly once';

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed batch principal outcomes reconcile by status',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
                    AND [ProcessingOutcome] = 'ACCEPTED'
              ) = 1600
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Audit].[audit].[RecordOutcome]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
                    AND [ProcessingOutcome] = 'QUARANTINED'
              ) = 5
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Accepted=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
              AND [ProcessingOutcome] = 'ACCEPTED'
        ),
        N'; Quarantined=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Audit].[audit].[RecordOutcome]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
              AND [ProcessingOutcome] = 'QUARANTINED'
        )
    );

INSERT INTO #ValidationResults
SELECT
    N'Latest mixed landing rows retain split source provenance',
    CASE
        WHEN
              (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[landing].[Admission]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
                    AND [SourceSystemCode] = 'LEGACY_PAS'
              ) = 1600
          AND (
                  SELECT COUNT_BIG(*)
                  FROM [Aegis_Staging].[landing].[Admission]
                  WHERE [BatchId] = @LatestMixedBatchId
                    AND [PackageExecutionId] =
                        @LatestMixedPackageExecutionId
                    AND [SourceSystemCode] =
                        'LEGACY_PAS_DEFECT_FILE'
                    AND [SourceFileName] =
                        N'admission_defects.csv'
              ) = 5
        THEN 1
        ELSE 0
    END,
    CONCAT
    (
        N'Valid source rows=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[landing].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
              AND [SourceSystemCode] = 'LEGACY_PAS'
        ),
        N'; Defect file rows=',
        (
            SELECT COUNT_BIG(*)
            FROM [Aegis_Staging].[landing].[Admission]
            WHERE [BatchId] = @LatestMixedBatchId
              AND [PackageExecutionId] =
                    @LatestMixedPackageExecutionId
              AND [SourceSystemCode] =
                    'LEGACY_PAS_DEFECT_FILE'
              AND [SourceFileName] =
                    N'admission_defects.csv'
        )
    );

/*
    Results
*/

SELECT
    [CheckNumber],
    [CheckName],
    [Result] =
        CASE
            WHEN [Passed] = 1 THEN 'PASS'
            ELSE 'FAIL'
        END,
    [ActualResult]
FROM #ValidationResults
ORDER BY [CheckNumber];

DECLARE @PassedCount INT =
(
    SELECT COUNT(*)
    FROM #ValidationResults
    WHERE [Passed] = 1
);

DECLARE @FailedCount INT =
(
    SELECT COUNT(*)
    FROM #ValidationResults
    WHERE [Passed] = 0
);

DECLARE @TotalCount INT =
(
    SELECT COUNT(*)
    FROM #ValidationResults
);

SELECT
    [TotalChecks] = @TotalCount,
    [PassedChecks] = @PassedCount,
    [FailedChecks] = @FailedCount,
    [LatestValidBatchId] = @LatestValidBatchId,
    [LatestValidPackageExecutionId] =
        @LatestValidPackageExecutionId,
    [LatestDefectBatchId] = @LatestDefectBatchId,
    [LatestDefectPackageExecutionId] =
        @LatestDefectPackageExecutionId,
    [LatestMixedBatchId] = @LatestMixedBatchId,
    [LatestMixedPackageExecutionId] =
        @LatestMixedPackageExecutionId;

IF @FailedCount > 0
BEGIN
    RAISERROR
    (
        'Aegis Day 3 control-plane validation failed.',
        16,
        1
    );
END;