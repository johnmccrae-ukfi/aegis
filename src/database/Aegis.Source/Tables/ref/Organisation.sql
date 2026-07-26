CREATE TABLE [ref].[Organisation]
(
    [OrganisationId]            INT            IDENTITY (1, 1) NOT NULL,
    [OrganisationCode]          VARCHAR(20)    NOT NULL,
    [NationalOrganisationCode]  VARCHAR(12)    NULL,
    [OrganisationName]          NVARCHAR(200)  NOT NULL,
    [OrganisationTypeCode]      VARCHAR(20)    NULL,
    [ParentOrganisationCode]    VARCHAR(20)    NULL,
    [Postcode]                  VARCHAR(8)     NULL,
    [EffectiveFromDate]         DATE           NULL,
    [EffectiveToDate]           DATE           NULL,
    [RecordCreatedAt]           DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]           DATETIME2(0)   NOT NULL,
    [IsDeleted]                 BIT            NOT NULL
        CONSTRAINT [DF_ref_Organisation_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_ref_Organisation]
        PRIMARY KEY CLUSTERED ([OrganisationId]),

    CONSTRAINT [UQ_ref_Organisation_OrganisationCode]
        UNIQUE ([OrganisationCode]),

    CONSTRAINT [CK_ref_Organisation_EffectiveDates]
        CHECK
        (
            [EffectiveToDate] IS NULL
            OR [EffectiveFromDate] IS NULL
            OR [EffectiveToDate] >= [EffectiveFromDate]
        )
);