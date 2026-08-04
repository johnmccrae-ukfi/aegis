CREATE PROCEDURE [audit].[usp_RecordAdfAdmissionsOutcomes]
    @BatchId            BIGINT,
    @PackageExecutionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @OutcomeRowCount    BIGINT,
        @ExceptionRowCount  BIGINT,
        @AcceptedRowCount   BIGINT,
        @QuarantinedRowCount BIGINT;

    IF @BatchId IS NULL OR @BatchId <= 0
    BEGIN
        THROW 51000, 'BatchId must be a positive value.', 1;
    END;

    IF @PackageExecutionId IS NULL OR @PackageExecutionId <= 0
    BEGIN
        THROW 51000, 'PackageExecutionId must be a positive value.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [audit].[PackageExecution]
        WHERE [PackageExecutionId] = @PackageExecutionId
          AND [BatchId] = @BatchId
    )
    BEGIN
        THROW 51000, 'The supplied batch and package execution do not exist.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [$(AegisStagingDatabase)].[stg].[Admission]
        WHERE [BatchId] = @BatchId
          AND [PackageExecutionId] = @PackageExecutionId
          AND [ProcessingOutcome] IS NOT NULL
    )
    BEGIN
        THROW 51000, 'No classified staging admissions were found.', 1;
    END;

    IF
    (
        SELECT COUNT_BIG(*)
        FROM [dq].[ValidationRule]
        WHERE [ValidationRuleCode] IN
        (
            'DQ-ADM-001',
            'DQ-ADM-002',
            'DQ-ADM-003',
            'DQ-ADM-004',
            'DQ-ADM-005'
        )
          AND [ValidationRuleVersion] = 1
          AND [IsActive] = 1
    ) <> 5
    BEGIN
        THROW 51000, 'One or more required admission validation rules are missing or inactive.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
            Remove any existing audit records for this execution so that
            controlled replays remain deterministic.
        */
        DELETE [Exception]
        FROM [dq].[DataQualityException] AS [Exception]
        WHERE [Exception].[BatchId] = @BatchId
          AND [Exception].[PackageExecutionId] = @PackageExecutionId
          AND [Exception].[SourceDomain] = 'PAS_ACTIVITY'
          AND [Exception].[SourceObject] = 'Admission';

        DELETE [Outcome]
        FROM [audit].[RecordOutcome] AS [Outcome]
        WHERE [Outcome].[BatchId] = @BatchId
          AND [Outcome].[PackageExecutionId] = @PackageExecutionId
          AND [Outcome].[SourceDomain] = 'PAS_ACTIVITY'
          AND [Outcome].[SourceObject] = 'Admission';

        /*
            Record one processing outcome for every classified admission.
        */
        INSERT INTO [audit].[RecordOutcome]
        (
            [BatchId],
            [PackageExecutionId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier],
            [SourceRowNumber],
            [LandingRecordId],
            [ProcessingOutcome],
            [OutcomeReasonCode],
            [OutcomeDetail],
            [ProcessedAt]
        )
        SELECT
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            'PAS_ACTIVITY',
            'Admission',
            [Staging].[SourceRecordIdentifier],
            [Staging].[SourceRowNumber],
            [Staging].[LandingAdmissionId],
            [Staging].[ProcessingOutcome],
            CASE
                WHEN [Staging].[ProcessingOutcome] = 'ACCEPTED'
                    THEN 'VALID_ADMISSION'
                WHEN [Staging].[ProcessingOutcome] = 'QUARANTINED'
                    THEN 'VALIDATION_FAILURE'
                ELSE NULL
            END,
            CASE
                WHEN [Staging].[ProcessingOutcome] = 'ACCEPTED'
                    THEN N'Admission passed all configured validation and lookup rules.'
                WHEN [Staging].[ProcessingOutcome] = 'QUARANTINED'
                    THEN N'Admission failed one or more configured validation or lookup rules.'
                ELSE NULL
            END,
            SYSUTCDATETIME()
        FROM [$(AegisStagingDatabase)].[stg].[Admission] AS [Staging]
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[ProcessingOutcome] IS NOT NULL;

        SET @OutcomeRowCount = @@ROWCOUNT;

        /*
            DQ-ADM-001:
            Discharge date and time must not precede admission.
        */
        INSERT INTO [dq].[DataQualityException]
        (
            [RecordOutcomeId],
            [BatchId],
            [PackageExecutionId],
            [ValidationRuleId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier],
            [SourceColumnName],
            [SourceValue],
            [ExpectedValue],
            [ErrorCode],
            [ErrorDetail],
            [ResolutionStatus],
            [QuarantinedAt]
        )
        SELECT
            [Outcome].[RecordOutcomeId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Rule].[ValidationRuleId],
            'PAS_ACTIVITY',
            'Admission',
            [Staging].[SourceRecordIdentifier],
            N'DischargeDateTime',
            CONVERT(NVARCHAR(50), [Staging].[DischargeDateTime], 126),
            N'DischargeDateTime must be greater than or equal to AdmissionDateTime.',
            [Rule].[ErrorCode],
            N'The discharge date and time occurs before the admission date and time.',
            'OPEN',
            SYSUTCDATETIME()
        FROM [$(AegisStagingDatabase)].[stg].[Admission] AS [Staging]
        INNER JOIN [audit].[RecordOutcome] AS [Outcome]
            ON [Outcome].[BatchId] = [Staging].[BatchId]
           AND [Outcome].[PackageExecutionId] = [Staging].[PackageExecutionId]
           AND [Outcome].[SourceDomain] = 'PAS_ACTIVITY'
           AND [Outcome].[SourceObject] = 'Admission'
           AND [Outcome].[SourceRecordIdentifier]
                = [Staging].[SourceRecordIdentifier]
        INNER JOIN [dq].[ValidationRule] AS [Rule]
            ON [Rule].[ValidationRuleCode] = 'DQ-ADM-001'
           AND [Rule].[ValidationRuleVersion] = 1
           AND [Rule].[IsActive] = 1
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[DischargeDateTime] < [Staging].[AdmissionDateTime];

        /*
            DQ-ADM-002:
            Open admissions must not contain discharge details.
        */
        INSERT INTO [dq].[DataQualityException]
        (
            [RecordOutcomeId],
            [BatchId],
            [PackageExecutionId],
            [ValidationRuleId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier],
            [SourceColumnName],
            [SourceValue],
            [ExpectedValue],
            [ErrorCode],
            [ErrorDetail],
            [ResolutionStatus],
            [QuarantinedAt]
        )
        SELECT
            [Outcome].[RecordOutcomeId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Rule].[ValidationRuleId],
            'PAS_ACTIVITY',
            'Admission',
            [Staging].[SourceRecordIdentifier],
            N'AdmissionStatusCode',
            [Staging].[AdmissionStatusCode],
            N'Open admissions must not contain discharge details.',
            [Rule].[ErrorCode],
            N'The admission is marked as open but contains one or more discharge values.',
            'OPEN',
            SYSUTCDATETIME()
        FROM [$(AegisStagingDatabase)].[stg].[Admission] AS [Staging]
        INNER JOIN [audit].[RecordOutcome] AS [Outcome]
            ON [Outcome].[BatchId] = [Staging].[BatchId]
           AND [Outcome].[PackageExecutionId] = [Staging].[PackageExecutionId]
           AND [Outcome].[SourceDomain] = 'PAS_ACTIVITY'
           AND [Outcome].[SourceObject] = 'Admission'
           AND [Outcome].[SourceRecordIdentifier]
                = [Staging].[SourceRecordIdentifier]
        INNER JOIN [dq].[ValidationRule] AS [Rule]
            ON [Rule].[ValidationRuleCode] = 'DQ-ADM-002'
           AND [Rule].[ValidationRuleVersion] = 1
           AND [Rule].[IsActive] = 1
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[AdmissionStatusCode] = 'OPEN'
          AND
          (
               [Staging].[DischargeDateTime] IS NOT NULL
            OR [Staging].[DischargeMethodCode] IS NOT NULL
            OR [Staging].[DischargeDestinationCode] IS NOT NULL
          );

        /*
            DQ-ADM-003:
            Discharged admissions require all discharge values.
        */
        INSERT INTO [dq].[DataQualityException]
        (
            [RecordOutcomeId],
            [BatchId],
            [PackageExecutionId],
            [ValidationRuleId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier],
            [SourceColumnName],
            [SourceValue],
            [ExpectedValue],
            [ErrorCode],
            [ErrorDetail],
            [ResolutionStatus],
            [QuarantinedAt]
        )
        SELECT
            [Outcome].[RecordOutcomeId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Rule].[ValidationRuleId],
            'PAS_ACTIVITY',
            'Admission',
            [Staging].[SourceRecordIdentifier],
            N'AdmissionStatusCode',
            [Staging].[AdmissionStatusCode],
            N'Discharged admissions must contain discharge date, method and destination.',
            [Rule].[ErrorCode],
            N'The admission is marked as discharged but one or more required discharge values are missing.',
            'OPEN',
            SYSUTCDATETIME()
        FROM [$(AegisStagingDatabase)].[stg].[Admission] AS [Staging]
        INNER JOIN [audit].[RecordOutcome] AS [Outcome]
            ON [Outcome].[BatchId] = [Staging].[BatchId]
           AND [Outcome].[PackageExecutionId] = [Staging].[PackageExecutionId]
           AND [Outcome].[SourceDomain] = 'PAS_ACTIVITY'
           AND [Outcome].[SourceObject] = 'Admission'
           AND [Outcome].[SourceRecordIdentifier]
                = [Staging].[SourceRecordIdentifier]
        INNER JOIN [dq].[ValidationRule] AS [Rule]
            ON [Rule].[ValidationRuleCode] = 'DQ-ADM-003'
           AND [Rule].[ValidationRuleVersion] = 1
           AND [Rule].[IsActive] = 1
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[AdmissionStatusCode] = 'DISCHARGED'
          AND
          (
               [Staging].[DischargeDateTime] IS NULL
            OR [Staging].[DischargeMethodCode] IS NULL
            OR [Staging].[DischargeDestinationCode] IS NULL
          );

        /*
            DQ-ADM-004:
            Patient must resolve to the source PAS.
        */
        INSERT INTO [dq].[DataQualityException]
        (
            [RecordOutcomeId],
            [BatchId],
            [PackageExecutionId],
            [ValidationRuleId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier],
            [SourceColumnName],
            [SourceValue],
            [ExpectedValue],
            [ErrorCode],
            [ErrorDetail],
            [ResolutionStatus],
            [QuarantinedAt]
        )
        SELECT
            [Outcome].[RecordOutcomeId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Rule].[ValidationRuleId],
            'PAS_ACTIVITY',
            'Admission',
            [Staging].[SourceRecordIdentifier],
            N'PatientId',
            CONVERT(NVARCHAR(50), [Staging].[PatientId]),
            N'PatientId must resolve to Aegis_Source.pas.Patient.',
            [Rule].[ErrorCode],
            N'The admission references an unknown patient.',
            'OPEN',
            SYSUTCDATETIME()
        FROM [$(AegisStagingDatabase)].[stg].[Admission] AS [Staging]
        INNER JOIN [audit].[RecordOutcome] AS [Outcome]
            ON [Outcome].[BatchId] = [Staging].[BatchId]
           AND [Outcome].[PackageExecutionId] = [Staging].[PackageExecutionId]
           AND [Outcome].[SourceDomain] = 'PAS_ACTIVITY'
           AND [Outcome].[SourceObject] = 'Admission'
           AND [Outcome].[SourceRecordIdentifier]
                = [Staging].[SourceRecordIdentifier]
        INNER JOIN [dq].[ValidationRule] AS [Rule]
            ON [Rule].[ValidationRuleCode] = 'DQ-ADM-004'
           AND [Rule].[ValidationRuleVersion] = 1
           AND [Rule].[IsActive] = 1
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[PatientLookupStatus] = 'NOT_FOUND';

        /*
            DQ-ADM-005:
            Organisation and site must resolve consistently.
        */
        INSERT INTO [dq].[DataQualityException]
        (
            [RecordOutcomeId],
            [BatchId],
            [PackageExecutionId],
            [ValidationRuleId],
            [SourceDomain],
            [SourceObject],
            [SourceRecordIdentifier],
            [SourceColumnName],
            [SourceValue],
            [ExpectedValue],
            [ErrorCode],
            [ErrorDetail],
            [ResolutionStatus],
            [QuarantinedAt]
        )
        SELECT
            [Outcome].[RecordOutcomeId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Rule].[ValidationRuleId],
            'PAS_ACTIVITY',
            'Admission',
            [Staging].[SourceRecordIdentifier],
            N'OrganisationId/SiteId',
            CONCAT
            (
                N'OrganisationId=',
                COALESCE
                (
                    CONVERT(NVARCHAR(50), [Staging].[OrganisationId]),
                    N'NULL'
                ),
                N'; SiteId=',
                COALESCE
                (
                    CONVERT(NVARCHAR(50), [Staging].[SiteId]),
                    N'NULL'
                )
            ),
            N'Organisation and site must resolve, and the site must belong to the organisation.',
            [Rule].[ErrorCode],
            N'The admission references an unknown or inconsistent organisation and site combination.',
            'OPEN',
            SYSUTCDATETIME()
        FROM [$(AegisStagingDatabase)].[stg].[Admission] AS [Staging]
        INNER JOIN [audit].[RecordOutcome] AS [Outcome]
            ON [Outcome].[BatchId] = [Staging].[BatchId]
           AND [Outcome].[PackageExecutionId] = [Staging].[PackageExecutionId]
           AND [Outcome].[SourceDomain] = 'PAS_ACTIVITY'
           AND [Outcome].[SourceObject] = 'Admission'
           AND [Outcome].[SourceRecordIdentifier]
                = [Staging].[SourceRecordIdentifier]
        INNER JOIN [dq].[ValidationRule] AS [Rule]
            ON [Rule].[ValidationRuleCode] = 'DQ-ADM-005'
           AND [Rule].[ValidationRuleVersion] = 1
           AND [Rule].[IsActive] = 1
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND
          (
               [Staging].[OrganisationLookupStatus] = 'NOT_FOUND'
            OR [Staging].[SiteLookupStatus] = 'NOT_FOUND'
          );

        SELECT
            @ExceptionRowCount = COUNT_BIG(*)
        FROM [dq].[DataQualityException]
        WHERE [BatchId] = @BatchId
          AND [PackageExecutionId] = @PackageExecutionId
          AND [SourceDomain] = 'PAS_ACTIVITY'
          AND [SourceObject] = 'Admission';

        SELECT
            @AcceptedRowCount =
                COALESCE
                (
                    SUM
                    (
                        CASE
                            WHEN [ProcessingOutcome] = 'ACCEPTED'
                                THEN CONVERT(BIGINT, 1)
                            ELSE CONVERT(BIGINT, 0)
                        END
                    ),
                    0
                ),
            @QuarantinedRowCount =
                COALESCE
                (
                    SUM
                    (
                        CASE
                            WHEN [ProcessingOutcome] = 'QUARANTINED'
                                THEN CONVERT(BIGINT, 1)
                            ELSE CONVERT(BIGINT, 0)
                        END
                    ),
                    0
                )
        FROM [audit].[RecordOutcome]
        WHERE [BatchId] = @BatchId
          AND [PackageExecutionId] = @PackageExecutionId
          AND [SourceDomain] = 'PAS_ACTIVITY'
          AND [SourceObject] = 'Admission';

        IF @OutcomeRowCount = 0
        BEGIN
            THROW 51000, 'No admission record outcomes were written.', 1;
        END;

        IF @ExceptionRowCount <> @QuarantinedRowCount
        BEGIN
            THROW 51000, 'Admission exception and quarantine counts do not reconcile.', 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            @BatchId AS [BatchId],
            @PackageExecutionId AS [PackageExecutionId],
            @OutcomeRowCount AS [OutcomeRowCount],
            @AcceptedRowCount AS [AcceptedRowCount],
            @QuarantinedRowCount AS [QuarantinedRowCount],
            @ExceptionRowCount AS [ExceptionRowCount];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;