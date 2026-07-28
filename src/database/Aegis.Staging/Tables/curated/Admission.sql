CREATE TABLE [curated].[Admission]
(
    [CuratedAdmissionId]       BIGINT         IDENTITY(1,1) NOT NULL,
    [StagingAdmissionId]       BIGINT         NOT NULL,
    [LandingAdmissionId]       BIGINT         NOT NULL,
    [BatchId]                  BIGINT         NOT NULL,
    [PackageExecutionId]       BIGINT         NOT NULL,

    [SourceSystemCode]         VARCHAR(50)     NOT NULL,
    [SourceRecordIdentifier]   NVARCHAR(200)   NOT NULL,
    [SourceRowNumber]          BIGINT          NULL,

    [AdmissionId]              INT             NOT NULL,
    [PatientId]                INT             NOT NULL,
    [OrganisationId]           INT             NOT NULL,
    [SiteId]                   INT             NOT NULL,
    [AdmissionNumber]          VARCHAR(30)     NOT NULL,
    [PatientPathwayId]         VARCHAR(30)     NULL,

    [AdmissionDateTime]        DATETIME2(0)    NOT NULL,
    [DischargeDateTime]        DATETIME2(0)    NULL,

    [AdmissionMethodCode]              VARCHAR(10) NULL,
    [AdmissionSourceCode]              VARCHAR(10) NULL,
    [PatientClassificationCode]        VARCHAR(10) NULL,
    [IntendedManagementCode]           VARCHAR(10) NULL,
    [DischargeMethodCode]              VARCHAR(10) NULL,
    [DischargeDestinationCode]         VARCHAR(10) NULL,
    [AdministrativeCategoryCode]       VARCHAR(10) NULL,
    [LegalStatusCode]                  VARCHAR(10) NULL,
    [AdmissionStatusCode]              VARCHAR(20) NULL,

    [RecordCreatedAt]          DATETIME2(0)    NULL,
    [RecordUpdatedAt]          DATETIME2(0)    NULL,
    [IsDeleted]                BIT             NOT NULL,

    [AcceptedAt]               DATETIME2(3)    NOT NULL,
    [CuratedAt]                DATETIME2(3)    NOT NULL
        CONSTRAINT [DF_curated_Admission_CuratedAt]
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_curated_Admission]
        PRIMARY KEY CLUSTERED ([CuratedAdmissionId]),

    CONSTRAINT [UQ_curated_Admission_StagingAdmissionId]
        UNIQUE ([StagingAdmissionId]),

    CONSTRAINT [FK_curated_Admission_StagingAdmission]
        FOREIGN KEY ([StagingAdmissionId])
        REFERENCES [stg].[Admission] ([StagingAdmissionId]),

    CONSTRAINT [CK_curated_Admission_BatchId]
        CHECK ([BatchId] > 0),

    CONSTRAINT [CK_curated_Admission_PackageExecutionId]
        CHECK ([PackageExecutionId] > 0),

    CONSTRAINT [CK_curated_Admission_SourceSystemCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceSystemCode]))) > 0),

    CONSTRAINT [CK_curated_Admission_SourceRecordIdentifier_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceRecordIdentifier]))) > 0),

    CONSTRAINT [CK_curated_Admission_SourceRowNumber]
        CHECK ([SourceRowNumber] IS NULL OR [SourceRowNumber] > 0),

    CONSTRAINT [CK_curated_Admission_DischargeDateTime]
        CHECK
        (
            [DischargeDateTime] IS NULL
            OR [DischargeDateTime] >= [AdmissionDateTime]
        ),

    CONSTRAINT [CK_curated_Admission_RecordUpdatedAt]
        CHECK
        (
            [RecordUpdatedAt] IS NULL
            OR [RecordCreatedAt] IS NULL
            OR [RecordUpdatedAt] >= [RecordCreatedAt]
        ),

    CONSTRAINT [CK_curated_Admission_CuratedAt]
        CHECK ([CuratedAt] >= [AcceptedAt])
);