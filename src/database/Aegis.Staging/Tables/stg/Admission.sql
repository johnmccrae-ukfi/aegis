CREATE TABLE [stg].[Admission]
(
    [StagingAdmissionId]         BIGINT IDENTITY (1, 1) NOT NULL,

    [LandingAdmissionId]         BIGINT                 NOT NULL,
    [BatchId]                    BIGINT                 NOT NULL,
    [PackageExecutionId]         BIGINT                 NOT NULL,

    [SourceSystemCode]           VARCHAR(50)            NOT NULL,
    [SourceRecordIdentifier]     NVARCHAR(200)          NOT NULL,
    [SourceRowNumber]            BIGINT                 NULL,

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

    [PatientLookupStatus]        VARCHAR(20)            NOT NULL
        CONSTRAINT [DF_stg_Admission_PatientLookupStatus]
        DEFAULT ('NOT_EVALUATED'),

    [OrganisationLookupStatus]   VARCHAR(20)            NOT NULL
        CONSTRAINT [DF_stg_Admission_OrganisationLookupStatus]
        DEFAULT ('NOT_EVALUATED'),

    [SiteLookupStatus]           VARCHAR(20)            NOT NULL
        CONSTRAINT [DF_stg_Admission_SiteLookupStatus]
        DEFAULT ('NOT_EVALUATED'),

    [ValidationStatus]           VARCHAR(20)            NOT NULL
        CONSTRAINT [DF_stg_Admission_ValidationStatus]
        DEFAULT ('NOT_VALIDATED'),

    [ProcessingOutcome]          VARCHAR(20)            NULL,
    [ValidationFailureCount]     INT                    NOT NULL
        CONSTRAINT [DF_stg_Admission_ValidationFailureCount]
        DEFAULT (0),

    [AcceptedAt]                 DATETIME2(3)           NULL,
    [ClassifiedAt]               DATETIME2(3)           NULL,
    [CreatedAt]                  DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_stg_Admission_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),

    [UpdatedAt]                  DATETIME2(3)           NULL,

    CONSTRAINT [PK_stg_Admission]
        PRIMARY KEY CLUSTERED ([StagingAdmissionId]),

    CONSTRAINT [UQ_stg_Admission_LandingAdmissionId]
        UNIQUE ([LandingAdmissionId]),

    CONSTRAINT [FK_stg_Admission_LandingAdmission]
        FOREIGN KEY ([LandingAdmissionId])
        REFERENCES [landing].[Admission] ([LandingAdmissionId]),

    CONSTRAINT [CK_stg_Admission_BatchId]
        CHECK ([BatchId] > 0),

    CONSTRAINT [CK_stg_Admission_PackageExecutionId]
        CHECK ([PackageExecutionId] > 0),

    CONSTRAINT [CK_stg_Admission_SourceSystemCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceSystemCode]))) > 0),

    CONSTRAINT [CK_stg_Admission_SourceRecordIdentifier_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceRecordIdentifier]))) > 0),

    CONSTRAINT [CK_stg_Admission_SourceRowNumber]
        CHECK ([SourceRowNumber] IS NULL OR [SourceRowNumber] > 0),

    CONSTRAINT [CK_stg_Admission_PatientLookupStatus]
        CHECK
        (
            [PatientLookupStatus] IN
            (
                'NOT_EVALUATED',
                'MATCHED',
                'NOT_FOUND',
                'AMBIGUOUS'
            )
        ),

    CONSTRAINT [CK_stg_Admission_OrganisationLookupStatus]
        CHECK
        (
            [OrganisationLookupStatus] IN
            (
                'NOT_EVALUATED',
                'MATCHED',
                'NOT_FOUND',
                'AMBIGUOUS'
            )
        ),

    CONSTRAINT [CK_stg_Admission_SiteLookupStatus]
        CHECK
        (
            [SiteLookupStatus] IN
            (
                'NOT_EVALUATED',
                'MATCHED',
                'NOT_FOUND',
                'AMBIGUOUS'
            )
        ),

    CONSTRAINT [CK_stg_Admission_ValidationStatus]
        CHECK
        (
            [ValidationStatus] IN
            (
                'NOT_VALIDATED',
                'VALID',
                'INVALID',
                'VALID_WITH_WARNINGS'
            )
        ),

    CONSTRAINT [CK_stg_Admission_ProcessingOutcome]
        CHECK
        (
            [ProcessingOutcome] IS NULL
            OR [ProcessingOutcome] IN
            (
                'ACCEPTED',
                'WARNING',
                'QUARANTINED',
                'REJECTED',
                'DUPLICATE',
                'CANCELLED'
            )
        ),

    CONSTRAINT [CK_stg_Admission_ValidationFailureCount]
        CHECK ([ValidationFailureCount] >= 0),

    CONSTRAINT [CK_stg_Admission_ClassificationConsistency]
        CHECK
        (
            (
                [ValidationStatus] = 'NOT_VALIDATED'
                AND [ProcessingOutcome] IS NULL
                AND [ClassifiedAt] IS NULL
                AND [AcceptedAt] IS NULL
            )
            OR
            (
                [ValidationStatus] <> 'NOT_VALIDATED'
                AND [ProcessingOutcome] IS NOT NULL
                AND [ClassifiedAt] IS NOT NULL
            )
        ),

    CONSTRAINT [CK_stg_Admission_AcceptedAt]
        CHECK
        (
            (
                [ProcessingOutcome] IN ('ACCEPTED', 'WARNING')
                AND [AcceptedAt] IS NOT NULL
            )
            OR
            (
                [ProcessingOutcome] IS NULL
                AND [AcceptedAt] IS NULL
            )
            OR
            (
                [ProcessingOutcome] IN
                (
                    'QUARANTINED',
                    'REJECTED',
                    'DUPLICATE',
                    'CANCELLED'
                )
                AND [AcceptedAt] IS NULL
            )
        ),

    CONSTRAINT [CK_stg_Admission_UpdatedAt]
        CHECK
        (
            [UpdatedAt] IS NULL
            OR [UpdatedAt] >= [CreatedAt]
        )
);