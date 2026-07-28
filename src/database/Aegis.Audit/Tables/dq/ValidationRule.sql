CREATE TABLE [dq].[ValidationRule]
(
    [ValidationRuleId]         INT IDENTITY (1, 1) NOT NULL,
    [ValidationRuleCode]       VARCHAR(50)         NOT NULL,
    [ValidationRuleVersion]    INT                 NOT NULL
        CONSTRAINT [DF_dq_ValidationRule_ValidationRuleVersion]
        DEFAULT (1),
    [RuleName]                 NVARCHAR(200)       NOT NULL,
    [RuleDescription]          NVARCHAR(2000)      NOT NULL,
    [SourceDomain]             VARCHAR(50)         NOT NULL,
    [SourceObject]             VARCHAR(128)        NOT NULL,
    [RuleCategory]             VARCHAR(30)         NOT NULL,
    [Severity]                 VARCHAR(20)         NOT NULL,
    [ExpectedOutcome]          VARCHAR(20)         NOT NULL,
    [ErrorCode]                VARCHAR(100)        NULL,
    [IsReplayable]             BIT                 NOT NULL
        CONSTRAINT [DF_dq_ValidationRule_IsReplayable]
        DEFAULT (1),
    [EffectiveFrom]            DATETIME2(3)        NOT NULL
        CONSTRAINT [DF_dq_ValidationRule_EffectiveFrom]
        DEFAULT (SYSUTCDATETIME()),
    [EffectiveTo]              DATETIME2(3)        NULL,
    [IsActive]                 BIT                 NOT NULL
        CONSTRAINT [DF_dq_ValidationRule_IsActive]
        DEFAULT (1),
    [CreatedAt]                DATETIME2(3)        NOT NULL
        CONSTRAINT [DF_dq_ValidationRule_CreatedAt]
        DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt]                DATETIME2(3)        NULL,

    CONSTRAINT [PK_dq_ValidationRule]
        PRIMARY KEY CLUSTERED ([ValidationRuleId]),

    CONSTRAINT [UQ_dq_ValidationRule_CodeVersion]
        UNIQUE
        (
            [ValidationRuleCode],
            [ValidationRuleVersion]
        ),

    CONSTRAINT [CK_dq_ValidationRule_ValidationRuleCode_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([ValidationRuleCode]))) > 0),

    CONSTRAINT [CK_dq_ValidationRule_ValidationRuleVersion]
        CHECK ([ValidationRuleVersion] > 0),

    CONSTRAINT [CK_dq_ValidationRule_RuleName_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([RuleName]))) > 0),

    CONSTRAINT [CK_dq_ValidationRule_RuleDescription_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([RuleDescription]))) > 0),

    CONSTRAINT [CK_dq_ValidationRule_SourceDomain_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceDomain]))) > 0),

    CONSTRAINT [CK_dq_ValidationRule_SourceObject_NotBlank]
        CHECK (LEN(LTRIM(RTRIM([SourceObject]))) > 0),

    CONSTRAINT [CK_dq_ValidationRule_RuleCategory]
        CHECK
        (
            [RuleCategory] IN
            (
                'STRUCTURE',
                'REFERENCE',
                'IDENTITY',
                'CHRONOLOGY',
                'DUPLICATE',
                'COMPLETENESS',
                'BUSINESS'
            )
        ),

    CONSTRAINT [CK_dq_ValidationRule_Severity]
        CHECK
        (
            [Severity] IN
            (
                'INFO',
                'WARNING',
                'ERROR',
                'CRITICAL'
            )
        ),

    CONSTRAINT [CK_dq_ValidationRule_ExpectedOutcome]
        CHECK
        (
            [ExpectedOutcome] IN
            (
                'ACCEPTED',
                'WARNING',
                'QUARANTINED',
                'REJECTED',
                'DUPLICATE'
            )
        ),

    CONSTRAINT [CK_dq_ValidationRule_EffectiveDates]
        CHECK
        (
            [EffectiveTo] IS NULL
            OR [EffectiveTo] >= [EffectiveFrom]
        ),

    CONSTRAINT [CK_dq_ValidationRule_UpdatedAt]
        CHECK
        (
            [UpdatedAt] IS NULL
            OR [UpdatedAt] >= [CreatedAt]
        )
);