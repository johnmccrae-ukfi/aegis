CREATE TABLE [pas].[Admission]
(
    [AdmissionId]                INT            IDENTITY (1, 1) NOT NULL,
    [PatientId]                  INT            NOT NULL,
    [OrganisationId]             INT            NULL,
    [SiteId]                     INT            NULL,

    [AdmissionNumber]            VARCHAR(30)    NOT NULL,
    [PatientPathwayId]           VARCHAR(30)    NULL,

    [AdmissionDateTime]           DATETIME2(0)   NULL,
    [DischargeDateTime]           DATETIME2(0)   NULL,

    [AdmissionMethodCode]        VARCHAR(10)    NULL,
    [AdmissionSourceCode]        VARCHAR(10)    NULL,
    [PatientClassificationCode]  VARCHAR(10)    NULL,
    [IntendedManagementCode]     VARCHAR(10)    NULL,

    [DischargeMethodCode]        VARCHAR(10)    NULL,
    [DischargeDestinationCode]   VARCHAR(10)    NULL,

    [AdministrativeCategoryCode] VARCHAR(10)    NULL,
    [LegalStatusCode]            VARCHAR(10)    NULL,
    [AdmissionStatusCode]        VARCHAR(20)    NULL,

    [RecordCreatedAt]            DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]            DATETIME2(0)   NOT NULL,
    [IsDeleted]                  BIT            NOT NULL
        CONSTRAINT [DF_pas_Admission_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_pas_Admission]
        PRIMARY KEY CLUSTERED ([AdmissionId]),

    CONSTRAINT [UQ_pas_Admission_AdmissionNumber]
        UNIQUE ([AdmissionNumber]),

    CONSTRAINT [FK_pas_Admission_Patient]
        FOREIGN KEY ([PatientId])
        REFERENCES [pas].[Patient] ([PatientId]),

    CONSTRAINT [FK_pas_Admission_Organisation]
        FOREIGN KEY ([OrganisationId])
        REFERENCES [ref].[Organisation] ([OrganisationId]),

    CONSTRAINT [FK_pas_Admission_Site]
        FOREIGN KEY ([SiteId])
        REFERENCES [ref].[Site] ([SiteId])
);