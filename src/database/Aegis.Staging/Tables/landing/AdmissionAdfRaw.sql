CREATE TABLE [landing].[AdmissionAdfRaw]
(
    [AdmissionAdfRawId] BIGINT IDENTITY(1, 1) NOT NULL,

    [AdmissionId] NVARCHAR(50) NULL,
    [PatientId] NVARCHAR(50) NULL,
    [OrganisationId] NVARCHAR(50) NULL,
    [SiteId] NVARCHAR(50) NULL,
    [AdmissionNumber] NVARCHAR(100) NULL,
    [PatientPathwayId] NVARCHAR(100) NULL,
    [AdmissionDateTime] NVARCHAR(50) NULL,
    [DischargeDateTime] NVARCHAR(50) NULL,
    [AdmissionMethodCode] NVARCHAR(50) NULL,
    [AdmissionSourceCode] NVARCHAR(50) NULL,
    [PatientClassificationCode] NVARCHAR(50) NULL,
    [IntendedManagementCode] NVARCHAR(50) NULL,
    [DischargeMethodCode] NVARCHAR(50) NULL,
    [DischargeDestinationCode] NVARCHAR(50) NULL,
    [AdministrativeCategoryCode] NVARCHAR(50) NULL,
    [LegalStatusCode] NVARCHAR(50) NULL,
    [AdmissionStatusCode] NVARCHAR(50) NULL,
    [RecordCreatedAt] NVARCHAR(50) NULL,
    [RecordUpdatedAt] NVARCHAR(50) NULL,
    [IsDeleted] NVARCHAR(20) NULL,

    [LoadedAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_AdmissionAdfRaw_LoadedAt]
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_AdmissionAdfRaw]
        PRIMARY KEY CLUSTERED ([AdmissionAdfRawId])
);