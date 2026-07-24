CREATE TABLE [ref].[Consultant]
(
    [ConsultantId]              INT            IDENTITY (1, 1) NOT NULL,
    [OrganisationId]            INT            NULL,
    [MainSpecialtyId]           INT            NULL,
    [ConsultantCode]            VARCHAR(30)    NOT NULL,
    [NationalConsultantCode]    VARCHAR(30)    NULL,
    [TitleCode]                 VARCHAR(10)    NULL,
    [FamilyName]                NVARCHAR(100)  NULL,
    [GivenName]                 NVARCHAR(100)  NULL,
    [DisplayName]               NVARCHAR(200)  NOT NULL,
    [EffectiveFromDate]         DATE           NULL,
    [EffectiveToDate]           DATE           NULL,
    [RecordCreatedAt]           DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]           DATETIME2(0)   NOT NULL,
    [IsDeleted]                 BIT            NOT NULL
        CONSTRAINT [DF_ref_Consultant_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_ref_Consultant]
        PRIMARY KEY CLUSTERED ([ConsultantId]),

    CONSTRAINT [UQ_ref_Consultant_ConsultantCode]
        UNIQUE ([ConsultantCode]),

    CONSTRAINT [FK_ref_Consultant_Organisation]
        FOREIGN KEY ([OrganisationId])
        REFERENCES [ref].[Organisation] ([OrganisationId]),

    CONSTRAINT [FK_ref_Consultant_MainSpecialty]
        FOREIGN KEY ([MainSpecialtyId])
        REFERENCES [ref].[Specialty] ([SpecialtyId]),

    CONSTRAINT [CK_ref_Consultant_EffectiveDates]
        CHECK
        (
            [EffectiveToDate] IS NULL
            OR [EffectiveFromDate] IS NULL
            OR [EffectiveToDate] >= [EffectiveFromDate]
        )
);