CREATE TABLE [quarantine].[Admission]
(
    [QuarantineAdmissionId]      BIGINT IDENTITY (1, 1) NOT NULL,

    [LandingAdmissionId]         BIGINT                 NOT NULL,
    [StagingAdmissionId]         BIGINT                 NULL,
    [BatchId]                    BIGINT                 NOT NULL,
    [PackageExecutionId]         BIGINT                 NOT NULL,

    [SourceSystemCode]           VARCHAR(50)            NOT NULL,
    [SourceFileName]             NVARCHAR(260)          NULL,
    [SourceRowNumber]            BIGINT                 NULL,
    [SourceRecordIdentifier]     NVARCHAR(200)          NOT NULL,

    [AdmissionId]                INT                    NULL,
    [PatientId]                  INT                    NULL,
    [OrganisationId]             INT                    NULL,
    [SiteId]                     INT                    NULL,

    [AdmissionNumber]            VARCHAR(30)            NULL,
    [PatientPathwayId]           VARCHAR(30)            NULL,

    [AdmissionDateTime]          DATETIME2(0)           NULL,
    [DischargeDateTime]          DATETIME2(0)           NULL,

    [AdmissionMethodCode]        VARCHAR(10)            NULL,
    [AdmissionSourceCode]        VARCHAR(10)            NULL,
    [PatientClassificationCode]  VARCHAR(10)            NULL,
    [IntendedManagementCode]     VARCHAR(10)            NULL,

    [DischargeMethodCode]        VARCHAR(10)            NULL,
    [DischargeDestinationCode]   VARCHAR(10)            NULL,

    [AdministrativeCategoryCode] VARCHAR(10)            NULL,
    [LegalStatusCode]            VARCHAR(10)            NULL,
    [AdmissionStatusCode]        VARCHAR(20)            NULL,

    [RecordCreatedAt]            DATETIME2(0)           NULL,
    [RecordUpdatedAt]            DATETIME2(0)           NULL,
    [IsDeleted]                  BIT                    NULL,

    [IsCurrent]                  BIT                    NOT NULL
        CONSTRAINT [DF_quarantine_Admission_IsCurrent]
        DEFAULT (0),

    [QuarantineReasonCode]       VARCHAR(100)           NOT NULL,
    [QuarantineReasonDetail]     NVARCHAR(2000)         NOT NULL,
    [ValidationFailureCount]     INT                    NOT NULL,

    [QuarantineStatus]           VARCHAR(30)            NOT NULL
        CONSTRAINT [DF_quarantine_Admission_QuarantineStatus]
        DEFAULT ('OPEN'),

    [CorrectedPayload]           NVARCHAR(MAX)          NULL,
    [CorrectionDetail]           NVARCHAR(2000)         NULL,
    [CorrectedBy]                NVARCHAR(256)           NULL,
    [CorrectedAt]                DATETIME2(3)           NULL,

    [ReplayRequestReference]     UNIQUEIDENTIFIER       NULL,
    [ReplayedAt]                 DATETIME2(3)           NULL,

    [QuarantinedAt]              DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_quarantine_Admission_QuarantinedAt]
        DEFAULT (SYSUTCDATETIME()),

    [CreatedAt]                  DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_quarantine_Admission_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),

    [UpdatedAt]                  DATETIME2(3)           NULL,

    CONSTRAINT [PK_quarantine_Admission]
        PRIMARY KEY CLUSTERED ([QuarantineAdmissionId]),

    CONSTRAINT [UQ_quarantine_Admission_Batch_LandingAdmission]
        UNIQUE
        (
            [BatchId],
            [LandingAdmissionId]
        ),

    CONSTRAINT [FK_quarantine_Admission_LandingAdmission]
        FOREIGN KEY ([LandingAdmissionId])
        REFERENCES [landing].[Admission] ([LandingAdmissionId]),

    CONSTRAINT [FK_quarantine_Admission_StagingAdmission]
        FOREIGN KEY ([StagingAdmissionId])
        REFERENCES [stg].[Admission] ([StagingAdmissionId]),

    CONSTRAINT [CK_quarantine_Admission_BatchId]
        CHECK ([BatchId] > 0),

    CONSTRAINT [CK_quarantine_Admission_PackageExecutionId]
        CHECK ([PackageExecutionId] > 0),

    CONSTRAINT [CK_quarantine_Admission_SourceSystemCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceSystemCode]))) > 0),

    CONSTRAINT [CK_quarantine_Admission_SourceRowNumber]
        CHECK ([SourceRowNumber] IS NULL OR [SourceRowNumber] > 0),

    CONSTRAINT [CK_quarantine_Admission_SourceRecordIdentifier_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceRecordIdentifier]))) > 0),

    CONSTRAINT [CK_quarantine_Admission_IsCurrent]
        CHECK ([IsCurrent] IN (0, 1)),

    CONSTRAINT [CK_quarantine_Admission_QuarantineReasonCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([QuarantineReasonCode]))) > 0),

    CONSTRAINT [CK_quarantine_Admission_QuarantineReasonDetail_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([QuarantineReasonDetail]))) > 0),

    CONSTRAINT [CK_quarantine_Admission_ValidationFailureCount]
        CHECK ([ValidationFailureCount] > 0),

    CONSTRAINT [CK_quarantine_Admission_QuarantineStatus]
        CHECK
        (
            [QuarantineStatus] IN
            (
                'OPEN',
                'UNDER_REVIEW',
                'CORRECTED',
                'REPLAY_PENDING',
                'REPLAYED',
                'ACCEPTED_AS_LEGACY',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_quarantine_Admission_CorrectionConsistency]
        CHECK
        (
            (
                [CorrectedAt] IS NULL
                AND [CorrectedBy] IS NULL
                AND [CorrectedPayload] IS NULL
                AND [CorrectionDetail] IS NULL
            )
            OR
            (
                [CorrectedAt] IS NOT NULL
                AND [CorrectedBy] IS NOT NULL
                AND [CorrectedPayload] IS NOT NULL
                AND [CorrectionDetail] IS NOT NULL
            )
        ),

    CONSTRAINT [CK_quarantine_Admission_ReplayReference]
        CHECK
        (
            (
                [QuarantineStatus] IN
                (
                    'OPEN',
                    'UNDER_REVIEW',
                    'CORRECTED',
                    'ACCEPTED_AS_LEGACY',
                    'CANCELLED'
                )
                AND [ReplayRequestReference] IS NULL
                AND [ReplayedAt] IS NULL
            )
            OR
            (
                [QuarantineStatus] = 'REPLAY_PENDING'
                AND [ReplayRequestReference] IS NOT NULL
                AND [ReplayedAt] IS NULL
            )
            OR
            (
                [QuarantineStatus] = 'REPLAYED'
                AND [ReplayRequestReference] IS NOT NULL
                AND [ReplayedAt] IS NOT NULL
            )
        ),

    CONSTRAINT [CK_quarantine_Admission_CorrectedAt]
        CHECK
        (
            [CorrectedAt] IS NULL
            OR [CorrectedAt] >= [QuarantinedAt]
        ),

    CONSTRAINT [CK_quarantine_Admission_ReplayedAt]
        CHECK
        (
            [ReplayedAt] IS NULL
            OR [ReplayedAt] >= [QuarantinedAt]
        ),

    CONSTRAINT [CK_quarantine_Admission_UpdatedAt]
        CHECK
        (
            [UpdatedAt] IS NULL
            OR [UpdatedAt] >= [CreatedAt]
        )
);