CREATE TABLE [pas].[Patient]
(
    [PatientId]                INT            IDENTITY (1, 1) NOT NULL,
    [HospitalNumber]           VARCHAR(20)    NOT NULL,
    [NhsNumber]                VARCHAR(10)    NULL,
    [NhsNumberStatusCode]      VARCHAR(2)     NULL,
    [FamilyName]               NVARCHAR(100)  NOT NULL,
    [GivenName]                NVARCHAR(100)  NOT NULL,
    [MiddleNames]              NVARCHAR(100)  NULL,
    [TitleCode]                VARCHAR(10)    NULL,
    [DateOfBirth]              DATE           NULL,
    [SexCode]                  VARCHAR(2)     NULL,
    [AddressLine1]             NVARCHAR(100)  NULL,
    [AddressLine2]             NVARCHAR(100)  NULL,
    [AddressLine3]             NVARCHAR(100)  NULL,
    [Postcode]                 VARCHAR(8)     NULL,
    [RegisteredGpCode]         VARCHAR(20)    NULL,
    [RegisteredPracticeCode]   VARCHAR(20)    NULL,
    [DateOfDeath]              DATE           NULL,
    [PatientStatusCode]        VARCHAR(10)    NULL,
    [RecordCreatedAt]          DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]          DATETIME2(0)   NOT NULL,
    [IsDeleted]                BIT            NOT NULL
        CONSTRAINT [DF_pas_Patient_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_pas_Patient]
        PRIMARY KEY CLUSTERED ([PatientId]),

    CONSTRAINT [UQ_pas_Patient_HospitalNumber]
        UNIQUE ([HospitalNumber]),

    CONSTRAINT [CK_pas_Patient_DateOfDeath]
        CHECK
        (
            [DateOfDeath] IS NULL
            OR [DateOfBirth] IS NULL
            OR [DateOfDeath] >= [DateOfBirth]
        )
);