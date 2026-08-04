CREATE PROCEDURE [landing].[usp_PromoteAdfAdmissionsRaw]
    @BatchId             BIGINT,
    @PackageExecutionId  BIGINT,
    @SourceFileName      NVARCHAR(260),
    @SourceExtractedAt   DATETIME2(3) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @ReceivedAt DATETIME2(3) = SYSUTCDATETIME(),
        @LandedAt DATETIME2(3),
        @RawRowCount BIGINT,
        @PromotedRowCount BIGINT;

    IF @BatchId <= 0
    BEGIN
        THROW 51000, 'BatchId must be greater than zero.', 1;
    END;

    IF @PackageExecutionId <= 0
    BEGIN
        THROW 51000, 'PackageExecutionId must be greater than zero.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@SourceFileName)), N'') IS NULL
    BEGIN
        THROW 51000, 'SourceFileName is required.', 1;
    END;

    IF @SourceExtractedAt IS NOT NULL
       AND @SourceExtractedAt > @ReceivedAt
    BEGIN
        THROW 51000, 'SourceExtractedAt cannot be later than ReceivedAt.', 1;
    END;

    SELECT
        @RawRowCount = COUNT_BIG(*)
    FROM [landing].[AdmissionAdfRaw];

    IF @RawRowCount = 0
    BEGIN
        THROW 51000, 'No rows were found in landing.AdmissionAdfRaw.', 1;
    END;

    SET @LandedAt = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
            Supports safe re-execution for the same audit identifiers
            without affecting rows belonging to other batches.
        */
        DELETE FROM [landing].[Admission]
        WHERE
            [BatchId] = @BatchId
            AND [PackageExecutionId] = @PackageExecutionId;

        ;WITH NumberedRaw AS
        (
            SELECT
                r.*,
                SourceRowNumber =
                    ROW_NUMBER() OVER
                    (
                        ORDER BY r.[AdmissionAdfRawId]
                    )
            FROM [landing].[AdmissionAdfRaw] AS r
        )
        INSERT INTO [landing].[Admission]
        (
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

            [ExtractedAt],
            [ReceivedAt],
            [LandedAt],
            [SourceRowHash]
        )
        SELECT
            @BatchId,
            @PackageExecutionId,
            'LEGACY_PAS',
            LTRIM(RTRIM(@SourceFileName)),
            r.[SourceRowNumber],

            CONCAT
            (
                N'ADMISSION:',
                COALESCE
                (
                    NULLIF(LTRIM(RTRIM(r.[AdmissionId])), N''),
                    CONCAT(N'RAW-', r.[AdmissionAdfRawId])
                )
            ),

            TRY_CONVERT
            (
                INT,
                NULLIF(LTRIM(RTRIM(r.[AdmissionId])), N'')
            ),
            TRY_CONVERT
            (
                INT,
                NULLIF(LTRIM(RTRIM(r.[PatientId])), N'')
            ),
            TRY_CONVERT
            (
                INT,
                NULLIF(LTRIM(RTRIM(r.[OrganisationId])), N'')
            ),
            TRY_CONVERT
            (
                INT,
                NULLIF(LTRIM(RTRIM(r.[SiteId])), N'')
            ),

            CASE
                WHEN LEN(LTRIM(RTRIM(r.[AdmissionNumber]))) <= 30
                    THEN NULLIF(LTRIM(RTRIM(r.[AdmissionNumber])), N'')
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[PatientPathwayId]))) <= 30
                    THEN NULLIF(LTRIM(RTRIM(r.[PatientPathwayId])), N'')
                ELSE NULL
            END,

            TRY_CONVERT
            (
                DATETIME2(0),
                NULLIF(LTRIM(RTRIM(r.[AdmissionDateTime])), N'')
            ),
            TRY_CONVERT
            (
                DATETIME2(0),
                NULLIF(LTRIM(RTRIM(r.[DischargeDateTime])), N'')
            ),

            CASE
                WHEN LEN(LTRIM(RTRIM(r.[AdmissionMethodCode]))) <= 10
                    THEN NULLIF(LTRIM(RTRIM(r.[AdmissionMethodCode])), N'')
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[AdmissionSourceCode]))) <= 10
                    THEN NULLIF(LTRIM(RTRIM(r.[AdmissionSourceCode])), N'')
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[PatientClassificationCode]))) <= 10
                    THEN NULLIF
                    (
                        LTRIM(RTRIM(r.[PatientClassificationCode])),
                        N''
                    )
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[IntendedManagementCode]))) <= 10
                    THEN NULLIF
                    (
                        LTRIM(RTRIM(r.[IntendedManagementCode])),
                        N''
                    )
                ELSE NULL
            END,

            CASE
                WHEN LEN(LTRIM(RTRIM(r.[DischargeMethodCode]))) <= 10
                    THEN NULLIF(LTRIM(RTRIM(r.[DischargeMethodCode])), N'')
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[DischargeDestinationCode]))) <= 10
                    THEN NULLIF
                    (
                        LTRIM(RTRIM(r.[DischargeDestinationCode])),
                        N''
                    )
                ELSE NULL
            END,

            CASE
                WHEN LEN(LTRIM(RTRIM(r.[AdministrativeCategoryCode]))) <= 10
                    THEN NULLIF
                    (
                        LTRIM(RTRIM(r.[AdministrativeCategoryCode])),
                        N''
                    )
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[LegalStatusCode]))) <= 10
                    THEN NULLIF(LTRIM(RTRIM(r.[LegalStatusCode])), N'')
                ELSE NULL
            END,
            CASE
                WHEN LEN(LTRIM(RTRIM(r.[AdmissionStatusCode]))) <= 20
                    THEN NULLIF(LTRIM(RTRIM(r.[AdmissionStatusCode])), N'')
                ELSE NULL
            END,

            TRY_CONVERT
            (
                DATETIME2(0),
                NULLIF(LTRIM(RTRIM(r.[RecordCreatedAt])), N'')
            ),
            TRY_CONVERT
            (
                DATETIME2(0),
                NULLIF(LTRIM(RTRIM(r.[RecordUpdatedAt])), N'')
            ),

            CASE LOWER(LTRIM(RTRIM(r.[IsDeleted])))
                WHEN '1' THEN CONVERT(BIT, 1)
                WHEN 'true' THEN CONVERT(BIT, 1)
                WHEN 'yes' THEN CONVERT(BIT, 1)
                WHEN 'y' THEN CONVERT(BIT, 1)
                WHEN '0' THEN CONVERT(BIT, 0)
                WHEN 'false' THEN CONVERT(BIT, 0)
                WHEN 'no' THEN CONVERT(BIT, 0)
                WHEN 'n' THEN CONVERT(BIT, 0)
                ELSE NULL
            END,

            @SourceExtractedAt,
            @ReceivedAt,
            @LandedAt,

            HASHBYTES
            (
                'SHA2_256',
                CONCAT_WS
                (
                    N'|',
                    r.[AdmissionId],
                    r.[PatientId],
                    r.[OrganisationId],
                    r.[SiteId],
                    r.[AdmissionNumber],
                    r.[PatientPathwayId],
                    r.[AdmissionDateTime],
                    r.[DischargeDateTime],
                    r.[AdmissionMethodCode],
                    r.[AdmissionSourceCode],
                    r.[PatientClassificationCode],
                    r.[IntendedManagementCode],
                    r.[DischargeMethodCode],
                    r.[DischargeDestinationCode],
                    r.[AdministrativeCategoryCode],
                    r.[LegalStatusCode],
                    r.[AdmissionStatusCode],
                    r.[RecordCreatedAt],
                    r.[RecordUpdatedAt],
                    r.[IsDeleted]
                )
            )
        FROM NumberedRaw AS r;

        SET @PromotedRowCount = @@ROWCOUNT;

        IF @PromotedRowCount <> @RawRowCount
        BEGIN
            THROW 51000, 'Raw and promoted row counts do not reconcile.', 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            @BatchId AS [BatchId],
            @PackageExecutionId AS [PackageExecutionId],
            @RawRowCount AS [RawRowCount],
            @PromotedRowCount AS [PromotedRowCount],
            @ReceivedAt AS [ReceivedAt],
            @LandedAt AS [LandedAt];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;