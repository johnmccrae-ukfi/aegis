CREATE TABLE [landing].[Admission]
(
    [LandingAdmissionId]         BIGINT IDENTITY (1, 1) NOT NULL,

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

    [ExtractedAt]                DATETIME2(3)           NULL,
    [ReceivedAt]                 DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_landing_Admission_ReceivedAt]
        DEFAULT (SYSUTCDATETIME()),
    [LandedAt]                   DATETIME2(3)           NOT NULL
        CONSTRAINT [DF_landing_Admission_LandedAt]
        DEFAULT (SYSUTCDATETIME()),
    [SourceRowHash]              VARBINARY(32)          NULL,

    CONSTRAINT [PK_landing_Admission]
        PRIMARY KEY CLUSTERED ([LandingAdmissionId]),

    CONSTRAINT [CK_landing_Admission_BatchId]
        CHECK ([BatchId] > 0),

    CONSTRAINT [CK_landing_Admission_PackageExecutionId]
        CHECK ([PackageExecutionId] > 0),

    CONSTRAINT [CK_landing_Admission_SourceSystemCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceSystemCode]))) > 0),

    CONSTRAINT [CK_landing_Admission_SourceRowNumber]
        CHECK ([SourceRowNumber] IS NULL OR [SourceRowNumber] > 0),

    CONSTRAINT [CK_landing_Admission_SourceRecordIdentifier_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceRecordIdentifier]))) > 0),

    CONSTRAINT [CK_landing_Admission_ExtractedAt]
        CHECK
        (
            [ExtractedAt] IS NULL
            OR [ExtractedAt] <= [ReceivedAt]
        ),

    CONSTRAINT [CK_landing_Admission_LandedAt]
        CHECK ([LandedAt] >= [ReceivedAt])
);