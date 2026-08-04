CREATE PROCEDURE [stg].[usp_ProcessAdfAdmissions]
    @BatchId            BIGINT,
    @PackageExecutionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @ClassifiedAt DATETIME2(3),
        @LandingRowCount    BIGINT,
        @StagingRowCount    BIGINT,
        @AcceptedRowCount   BIGINT,
        @QuarantinedRowCount BIGINT,
        @RejectedRowCount   BIGINT,
        @WarningRowCount    BIGINT,
        @DuplicateRowCount  BIGINT;

    IF @BatchId IS NULL OR @BatchId <= 0
    BEGIN
        THROW 51000, 'BatchId must be a positive value.', 1;
    END;

    IF @PackageExecutionId IS NULL OR @PackageExecutionId <= 0
    BEGIN
        THROW 51000, 'PackageExecutionId must be a positive value.', 1;
    END;

    SELECT
        @LandingRowCount = COUNT_BIG(*)
    FROM [landing].[Admission]
    WHERE [BatchId] = @BatchId
      AND [PackageExecutionId] = @PackageExecutionId;

    IF @LandingRowCount = 0
    BEGIN
        THROW 51000, 'No landing admissions were found for the supplied batch and package execution.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
            Remove materialised results for this execution so that a controlled
            replay produces the same deterministic result.
        */
        DELETE [Curated]
        FROM [curated].[Admission] AS [Curated]
        WHERE [Curated].[BatchId] = @BatchId
          AND [Curated].[PackageExecutionId] = @PackageExecutionId;

        DELETE [Quarantine]
        FROM [quarantine].[Admission] AS [Quarantine]
        WHERE [Quarantine].[BatchId] = @BatchId
          AND [Quarantine].[PackageExecutionId] = @PackageExecutionId;

        DELETE [Staging]
        FROM [stg].[Admission] AS [Staging]
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId;

        /*
            Copy the promoted landing rows into the typed staging layer.
            Lookup and classification fields are populated in the following
            update step.
        */
        INSERT INTO [stg].[Admission]
        (
            [LandingAdmissionId],
            [BatchId],
            [PackageExecutionId],
            [SourceSystemCode],
            [SourceRecordIdentifier],
            [SourceRowNumber],
            [AdmissionId],
            [PatientId],
            [OrganisationId],
            [SiteId],
            [AdmissionNumber],
            [PatientPathwayId],
            [AdmissionDateTime],
            [DischargeDateTime],
            [AdmissionMethodCode],
            [AdmissionSourceCode],
            [PatientClassificationCode],
            [IntendedManagementCode],
            [DischargeMethodCode],
            [DischargeDestinationCode],
            [AdministrativeCategoryCode],
            [LegalStatusCode],
            [AdmissionStatusCode],
            [RecordCreatedAt],
            [RecordUpdatedAt],
            [IsDeleted]
        )
        SELECT
            [Landing].[LandingAdmissionId],
            [Landing].[BatchId],
            [Landing].[PackageExecutionId],
            [Landing].[SourceSystemCode],
            [Landing].[SourceRecordIdentifier],
            [Landing].[SourceRowNumber],
            [Landing].[AdmissionId],
            [Landing].[PatientId],
            [Landing].[OrganisationId],
            [Landing].[SiteId],
            [Landing].[AdmissionNumber],
            [Landing].[PatientPathwayId],
            [Landing].[AdmissionDateTime],
            [Landing].[DischargeDateTime],
            [Landing].[AdmissionMethodCode],
            [Landing].[AdmissionSourceCode],
            [Landing].[PatientClassificationCode],
            [Landing].[IntendedManagementCode],
            [Landing].[DischargeMethodCode],
            [Landing].[DischargeDestinationCode],
            [Landing].[AdministrativeCategoryCode],
            [Landing].[LegalStatusCode],
            [Landing].[AdmissionStatusCode],
            [Landing].[RecordCreatedAt],
            [Landing].[RecordUpdatedAt],
            [Landing].[IsDeleted]
        FROM [landing].[Admission] AS [Landing]
        WHERE [Landing].[BatchId] = @BatchId
          AND [Landing].[PackageExecutionId] = @PackageExecutionId;

        SET @StagingRowCount = @@ROWCOUNT;

        IF @StagingRowCount <> @LandingRowCount
        BEGIN
            THROW 51000, 'Landing and staging admission counts do not reconcile.', 1;
        END;

        SET @ClassifiedAt = SYSUTCDATETIME();

        /*
            Apply the same five Admissions rules used by the SSIS mixed
            package.

            DQ-ADM-001:
                DischargeDateTime precedes AdmissionDateTime.

            DQ-ADM-002:
                An OPEN admission contains discharge details.

            DQ-ADM-003:
                A DISCHARGED admission is missing required discharge details.

            DQ-ADM-004:
                PatientId does not resolve to an active PAS patient.

            DQ-ADM-005:
                Organisation or site does not resolve, or the site does not
                belong to the supplied organisation.
        */
        ;WITH [Classification] AS
        (
            SELECT
                [Staging].[StagingAdmissionId],

                CASE
                    WHEN [Patient].[PatientId] IS NULL
                        THEN 'NOT_FOUND'
                    ELSE 'MATCHED'
                END AS [PatientLookupStatus],

                CASE
                    WHEN [Organisation].[OrganisationId] IS NULL
                        THEN 'NOT_FOUND'
                    ELSE 'MATCHED'
                END AS [OrganisationLookupStatus],

                CASE
                    WHEN [Site].[SiteId] IS NULL
                        THEN 'NOT_FOUND'
                    ELSE 'MATCHED'
                END AS [SiteLookupStatus],

                CONVERT
                (
                    INT,
                    CASE
                        WHEN
                            [Staging].[DischargeDateTime] IS NOT NULL
                            AND [Staging].[AdmissionDateTime] IS NOT NULL
                            AND [Staging].[DischargeDateTime]
                                < [Staging].[AdmissionDateTime]
                            THEN 1
                        ELSE 0
                    END
                    +
                    CASE
                        WHEN
                            [Staging].[AdmissionStatusCode] = 'OPEN'
                            AND
                            (
                                   [Staging].[DischargeDateTime] IS NOT NULL
                                OR [Staging].[DischargeMethodCode] IS NOT NULL
                                OR [Staging].[DischargeDestinationCode] IS NOT NULL
                            )
                            THEN 1
                        ELSE 0
                    END
                    +
                    CASE
                        WHEN
                            [Staging].[AdmissionStatusCode] = 'DISCHARGED'
                            AND
                            (
                                   [Staging].[DischargeDateTime] IS NULL
                                OR [Staging].[DischargeMethodCode] IS NULL
                                OR [Staging].[DischargeDestinationCode] IS NULL
                            )
                            THEN 1
                        ELSE 0
                    END
                    +
                    CASE
                        WHEN [Patient].[PatientId] IS NULL
                            THEN 1
                        ELSE 0
                    END
                    +
                    CASE
                        WHEN
                               [Organisation].[OrganisationId] IS NULL
                            OR [Site].[SiteId] IS NULL
                            THEN 1
                        ELSE 0
                    END
                ) AS [ValidationFailureCount]
            FROM [stg].[Admission] AS [Staging]
            LEFT JOIN [$(AegisSourceDatabase)].[pas].[Patient] AS [Patient]
                ON [Patient].[PatientId] = [Staging].[PatientId]
               AND [Patient].[IsDeleted] = 0
            LEFT JOIN [$(AegisSourceDatabase)].[ref].[Organisation]
                AS [Organisation]
                ON [Organisation].[OrganisationId]
                    = [Staging].[OrganisationId]
               AND [Organisation].[IsDeleted] = 0
            LEFT JOIN [$(AegisSourceDatabase)].[ref].[Site] AS [Site]
                ON [Site].[SiteId] = [Staging].[SiteId]
               AND [Site].[OrganisationId] = [Staging].[OrganisationId]
               AND [Site].[IsDeleted] = 0
            WHERE [Staging].[BatchId] = @BatchId
              AND [Staging].[PackageExecutionId] = @PackageExecutionId
        )
        UPDATE [Staging]
        SET
            [Staging].[PatientLookupStatus]
                = [Classification].[PatientLookupStatus],

            [Staging].[OrganisationLookupStatus]
                = [Classification].[OrganisationLookupStatus],

            [Staging].[SiteLookupStatus]
                = [Classification].[SiteLookupStatus],

            [Staging].[ValidationFailureCount]
                = [Classification].[ValidationFailureCount],

            [Staging].[ValidationStatus] =
                CASE
                    WHEN [Classification].[ValidationFailureCount] = 0
                        THEN 'VALID'
                    ELSE 'INVALID'
                END,

            [Staging].[ProcessingOutcome] =
                CASE
                    WHEN [Classification].[ValidationFailureCount] = 0
                        THEN 'ACCEPTED'
                    ELSE 'QUARANTINED'
                END,

            [Staging].[AcceptedAt] =
                CASE
                    WHEN [Classification].[ValidationFailureCount] = 0
                        THEN @ClassifiedAt
                    ELSE NULL
                END,

            [Staging].[ClassifiedAt] = @ClassifiedAt,
            [Staging].[UpdatedAt] = @ClassifiedAt
        FROM [stg].[Admission] AS [Staging]
        INNER JOIN [Classification]
            ON [Classification].[StagingAdmissionId]
                = [Staging].[StagingAdmissionId];

        /*
            Materialise admissions that passed every configured rule.
        */
        INSERT INTO [curated].[Admission]
        (
            [StagingAdmissionId],
            [LandingAdmissionId],
            [BatchId],
            [PackageExecutionId],
            [SourceSystemCode],
            [SourceRecordIdentifier],
            [SourceRowNumber],
            [AdmissionId],
            [PatientId],
            [OrganisationId],
            [SiteId],
            [AdmissionNumber],
            [PatientPathwayId],
            [AdmissionDateTime],
            [DischargeDateTime],
            [AdmissionMethodCode],
            [AdmissionSourceCode],
            [PatientClassificationCode],
            [IntendedManagementCode],
            [DischargeMethodCode],
            [DischargeDestinationCode],
            [AdministrativeCategoryCode],
            [LegalStatusCode],
            [AdmissionStatusCode],
            [RecordCreatedAt],
            [RecordUpdatedAt],
            [IsDeleted],
            [AcceptedAt]
        )
        SELECT
            [Staging].[StagingAdmissionId],
            [Staging].[LandingAdmissionId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Staging].[SourceSystemCode],
            [Staging].[SourceRecordIdentifier],
            [Staging].[SourceRowNumber],
            [Staging].[AdmissionId],
            [Staging].[PatientId],
            [Staging].[OrganisationId],
            [Staging].[SiteId],
            [Staging].[AdmissionNumber],
            [Staging].[PatientPathwayId],
            [Staging].[AdmissionDateTime],
            [Staging].[DischargeDateTime],
            [Staging].[AdmissionMethodCode],
            [Staging].[AdmissionSourceCode],
            [Staging].[PatientClassificationCode],
            [Staging].[IntendedManagementCode],
            [Staging].[DischargeMethodCode],
            [Staging].[DischargeDestinationCode],
            [Staging].[AdministrativeCategoryCode],
            [Staging].[LegalStatusCode],
            [Staging].[AdmissionStatusCode],
            [Staging].[RecordCreatedAt],
            [Staging].[RecordUpdatedAt],
            [Staging].[IsDeleted],
            [Staging].[AcceptedAt]
        FROM [stg].[Admission] AS [Staging]
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[ProcessingOutcome] = 'ACCEPTED';

        SET @AcceptedRowCount = @@ROWCOUNT;

        /*
            Materialise admissions that failed one or more rules.

            QuarantineReasonCode records the first failed rule using the
            established SSIS precedence. ValidationFailureCount retains the
            total number of failed rules.
        */
        INSERT INTO [quarantine].[Admission]
        (
            [LandingAdmissionId],
            [StagingAdmissionId],
            [BatchId],
            [PackageExecutionId],
            [SourceSystemCode],
            [SourceFileName],
            [SourceRowNumber],
            [SourceRecordIdentifier],
            [AdmissionId],
            [PatientId],
            [OrganisationId],
            [SiteId],
            [AdmissionNumber],
            [PatientPathwayId],
            [AdmissionDateTime],
            [DischargeDateTime],
            [AdmissionMethodCode],
            [AdmissionSourceCode],
            [PatientClassificationCode],
            [IntendedManagementCode],
            [DischargeMethodCode],
            [DischargeDestinationCode],
            [AdministrativeCategoryCode],
            [LegalStatusCode],
            [AdmissionStatusCode],
            [RecordCreatedAt],
            [RecordUpdatedAt],
            [IsDeleted],
            [QuarantineReasonCode],
            [QuarantineReasonDetail],
            [ValidationFailureCount]
        )
        SELECT
            [Staging].[LandingAdmissionId],
            [Staging].[StagingAdmissionId],
            [Staging].[BatchId],
            [Staging].[PackageExecutionId],
            [Staging].[SourceSystemCode],
            [Landing].[SourceFileName],
            [Staging].[SourceRowNumber],
            [Staging].[SourceRecordIdentifier],
            [Staging].[AdmissionId],
            [Staging].[PatientId],
            [Staging].[OrganisationId],
            [Staging].[SiteId],
            [Staging].[AdmissionNumber],
            [Staging].[PatientPathwayId],
            [Staging].[AdmissionDateTime],
            [Staging].[DischargeDateTime],
            [Staging].[AdmissionMethodCode],
            [Staging].[AdmissionSourceCode],
            [Staging].[PatientClassificationCode],
            [Staging].[IntendedManagementCode],
            [Staging].[DischargeMethodCode],
            [Staging].[DischargeDestinationCode],
            [Staging].[AdministrativeCategoryCode],
            [Staging].[LegalStatusCode],
            [Staging].[AdmissionStatusCode],
            [Staging].[RecordCreatedAt],
            [Staging].[RecordUpdatedAt],
            [Staging].[IsDeleted],

            CASE
                WHEN
                    [Staging].[DischargeDateTime] IS NOT NULL
                    AND [Staging].[AdmissionDateTime] IS NOT NULL
                    AND [Staging].[DischargeDateTime]
                        < [Staging].[AdmissionDateTime]
                    THEN 'DQ-ADM-001'

                WHEN
                    [Staging].[AdmissionStatusCode] = 'OPEN'
                    AND
                    (
                           [Staging].[DischargeDateTime] IS NOT NULL
                        OR [Staging].[DischargeMethodCode] IS NOT NULL
                        OR [Staging].[DischargeDestinationCode] IS NOT NULL
                    )
                    THEN 'DQ-ADM-002'

                WHEN
                    [Staging].[AdmissionStatusCode] = 'DISCHARGED'
                    AND
                    (
                           [Staging].[DischargeDateTime] IS NULL
                        OR [Staging].[DischargeMethodCode] IS NULL
                        OR [Staging].[DischargeDestinationCode] IS NULL
                    )
                    THEN 'DQ-ADM-003'

                WHEN [Staging].[PatientLookupStatus] = 'NOT_FOUND'
                    THEN 'DQ-ADM-004'

                WHEN
                       [Staging].[OrganisationLookupStatus] = 'NOT_FOUND'
                    OR [Staging].[SiteLookupStatus] = 'NOT_FOUND'
                    THEN 'DQ-ADM-005'

                ELSE 'DQ-ADM-UNCLASSIFIED'
            END,

            CASE
                WHEN
                    [Staging].[DischargeDateTime] IS NOT NULL
                    AND [Staging].[AdmissionDateTime] IS NOT NULL
                    AND [Staging].[DischargeDateTime]
                        < [Staging].[AdmissionDateTime]
                    THEN N'Discharge date and time occurs before admission date and time.'

                WHEN
                    [Staging].[AdmissionStatusCode] = 'OPEN'
                    AND
                    (
                           [Staging].[DischargeDateTime] IS NOT NULL
                        OR [Staging].[DischargeMethodCode] IS NOT NULL
                        OR [Staging].[DischargeDestinationCode] IS NOT NULL
                    )
                    THEN N'Open admission contains one or more discharge values.'

                WHEN
                    [Staging].[AdmissionStatusCode] = 'DISCHARGED'
                    AND
                    (
                           [Staging].[DischargeDateTime] IS NULL
                        OR [Staging].[DischargeMethodCode] IS NULL
                        OR [Staging].[DischargeDestinationCode] IS NULL
                    )
                    THEN N'Discharged admission is missing one or more required discharge values.'

                WHEN [Staging].[PatientLookupStatus] = 'NOT_FOUND'
                    THEN N'Patient identifier does not resolve to an active PAS patient.'

                WHEN
                       [Staging].[OrganisationLookupStatus] = 'NOT_FOUND'
                    OR [Staging].[SiteLookupStatus] = 'NOT_FOUND'
                    THEN N'Organisation or site does not resolve, or the site does not belong to the supplied organisation.'

                ELSE N'Admission failed validation but no configured reason was identified.'
            END,

            [Staging].[ValidationFailureCount]
        FROM [stg].[Admission] AS [Staging]
        INNER JOIN [landing].[Admission] AS [Landing]
            ON [Landing].[LandingAdmissionId]
                = [Staging].[LandingAdmissionId]
        WHERE [Staging].[BatchId] = @BatchId
          AND [Staging].[PackageExecutionId] = @PackageExecutionId
          AND [Staging].[ProcessingOutcome] = 'QUARANTINED';

        SET @QuarantinedRowCount = @@ROWCOUNT;

        SELECT
            @RejectedRowCount =
                COUNT_BIG
                (
                    CASE
                        WHEN [ProcessingOutcome] = 'REJECTED' THEN 1
                    END
                ),
            @WarningRowCount =
                COUNT_BIG
                (
                    CASE
                        WHEN [ProcessingOutcome] = 'WARNING' THEN 1
                    END
                ),
            @DuplicateRowCount =
                COUNT_BIG
                (
                    CASE
                        WHEN [ProcessingOutcome] = 'DUPLICATE' THEN 1
                    END
                )
        FROM [stg].[Admission]
        WHERE [BatchId] = @BatchId
          AND [PackageExecutionId] = @PackageExecutionId;

        IF @AcceptedRowCount + @QuarantinedRowCount
            + @RejectedRowCount + @WarningRowCount
            + @DuplicateRowCount <> @StagingRowCount
        BEGIN
            THROW 51000, 'Classified admission counts do not reconcile with staging.', 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            @BatchId AS [BatchId],
            @PackageExecutionId AS [PackageExecutionId],
            @LandingRowCount AS [LandingRowCount],
            @StagingRowCount AS [StagingRowCount],
            @AcceptedRowCount AS [AcceptedRowCount],
            @RejectedRowCount AS [RejectedRowCount],
            @QuarantinedRowCount AS [QuarantinedRowCount],
            @WarningRowCount AS [WarningRowCount],
            @DuplicateRowCount AS [DuplicateRowCount];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;