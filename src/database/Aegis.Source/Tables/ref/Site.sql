CREATE TABLE [ref].[Site]
(
    [SiteId]                 INT            IDENTITY (1, 1) NOT NULL,
    [OrganisationId]         INT            NOT NULL,
    [SiteCode]               VARCHAR(20)    NOT NULL,
    [NationalSiteCode]       VARCHAR(12)    NULL,
    [SiteName]               NVARCHAR(200)  NOT NULL,
    [AddressLine1]           NVARCHAR(100)  NULL,
    [AddressLine2]           NVARCHAR(100)  NULL,
    [AddressLine3]           NVARCHAR(100)  NULL,
    [Postcode]               VARCHAR(8)     NULL,
    [EffectiveFromDate]      DATE           NULL,
    [EffectiveToDate]        DATE           NULL,
    [RecordCreatedAt]        DATETIME2(0)   NOT NULL,
    [RecordUpdatedAt]        DATETIME2(0)   NOT NULL,
    [IsDeleted]              BIT            NOT NULL
        CONSTRAINT [DF_ref_Site_IsDeleted]
        DEFAULT (0),

    CONSTRAINT [PK_ref_Site]
        PRIMARY KEY CLUSTERED ([SiteId]),

    CONSTRAINT [UQ_ref_Site_Organisation_SiteCode]
        UNIQUE ([OrganisationId], [SiteCode]),

    CONSTRAINT [FK_ref_Site_Organisation]
        FOREIGN KEY ([OrganisationId])
        REFERENCES [ref].[Organisation] ([OrganisationId]),

    CONSTRAINT [CK_ref_Site_EffectiveDates]
        CHECK
        (
            [EffectiveToDate] IS NULL
            OR [EffectiveFromDate] IS NULL
            OR [EffectiveToDate] >= [EffectiveFromDate]
        )
);