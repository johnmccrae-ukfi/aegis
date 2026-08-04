/*
    Aegis.Audit post-deployment reference data

    Purpose:
    - Seed governed interface definitions.
    - Seed the initial admission validation-rule catalogue.
    - Remain safe to execute repeatedly during DACPAC publication.
*/

SET NOCOUNT ON;
GO

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    /*
        Interface catalogue
    */

    MERGE [audit].[Interface] AS [Target]
    USING
    (
        VALUES
        (
            'PAS_ADMISSION_EXTRACT',
            N'PAS Admission Extract',
            'INBOUND',
            'LEGACY_PAS',
            'AEGIS_STAGING',
            'FILE',
            'CSV',
            N'Synthetic legacy PAS admitted-patient extract processed through the Aegis staging and audit control plane.',
            CONVERT(BIT, 1)
        )
    ) AS [Source]
    (
        [InterfaceCode],
        [InterfaceName],
        [InterfaceDirection],
        [SourceSystemCode],
        [TargetSystemCode],
        [TransportType],
        [DataFormat],
        [Description],
        [IsActive]
    )
        ON [Target].[InterfaceCode] = [Source].[InterfaceCode]

    WHEN MATCHED AND
    (
           [Target].[InterfaceName] <> [Source].[InterfaceName]
        OR [Target].[InterfaceDirection] <> [Source].[InterfaceDirection]
        OR [Target].[SourceSystemCode] <> [Source].[SourceSystemCode]
        OR [Target].[TargetSystemCode] <> [Source].[TargetSystemCode]
        OR [Target].[TransportType] <> [Source].[TransportType]
        OR [Target].[DataFormat] <> [Source].[DataFormat]
        OR ISNULL([Target].[Description], N'') <> ISNULL([Source].[Description], N'')
        OR [Target].[IsActive] <> [Source].[IsActive]
    )
    THEN UPDATE SET
        [InterfaceName] = [Source].[InterfaceName],
        [InterfaceDirection] = [Source].[InterfaceDirection],
        [SourceSystemCode] = [Source].[SourceSystemCode],
        [TargetSystemCode] = [Source].[TargetSystemCode],
        [TransportType] = [Source].[TransportType],
        [DataFormat] = [Source].[DataFormat],
        [Description] = [Source].[Description],
        [IsActive] = [Source].[IsActive],
        [UpdatedAt] = SYSUTCDATETIME()

    WHEN NOT MATCHED BY TARGET
    THEN INSERT
    (
        [InterfaceCode],
        [InterfaceName],
        [InterfaceDirection],
        [SourceSystemCode],
        [TargetSystemCode],
        [TransportType],
        [DataFormat],
        [Description],
        [IsActive]
    )
    VALUES
    (
        [Source].[InterfaceCode],
        [Source].[InterfaceName],
        [Source].[InterfaceDirection],
        [Source].[SourceSystemCode],
        [Source].[TargetSystemCode],
        [Source].[TransportType],
        [Source].[DataFormat],
        [Source].[Description],
        [Source].[IsActive]
    );

    /*
        Admission validation-rule catalogue
    */

    MERGE [dq].[ValidationRule] AS [Target]
    USING
    (
        VALUES
        (
            'DQ-ADM-001',
            1,
            N'Discharge before admission',
            N'The discharge date and time must not be earlier than the admission date and time.',
            'PAS_ACTIVITY',
            'Admission',
            'CHRONOLOGY',
            'ERROR',
            'QUARANTINED',
            'AEGIS-DQ-ADM-001',
            CONVERT(BIT, 1),
            CONVERT(BIT, 1)
        ),
        (
            'DQ-ADM-002',
            1,
            N'Open admission contains discharge details',
            N'An admission classified as open must not contain a discharge date, discharge method or discharge destination.',
            'PAS_ACTIVITY',
            'Admission',
            'BUSINESS',
            'ERROR',
            'QUARANTINED',
            'AEGIS-DQ-ADM-002',
            CONVERT(BIT, 1),
            CONVERT(BIT, 1)
        ),
        (
            'DQ-ADM-003',
            1,
            N'Discharged admission missing discharge details',
            N'An admission classified as discharged must contain the required discharge date, method and destination values.',
            'PAS_ACTIVITY',
            'Admission',
            'COMPLETENESS',
            'ERROR',
            'QUARANTINED',
            'AEGIS-DQ-ADM-003',
            CONVERT(BIT, 1),
            CONVERT(BIT, 1)
        ),
        (
            'DQ-ADM-004',
            1,
            N'Unknown patient',
            N'The admission patient identifier does not resolve to a known patient in the legacy PAS source.',
            'PAS_ACTIVITY',
            'Admission',
            'IDENTITY',
            'CRITICAL',
            'QUARANTINED',
            'AEGIS-DQ-ADM-004',
            CONVERT(BIT, 1),
            CONVERT(BIT, 1)
        ),
        (
            'DQ-ADM-005',
            1,
            N'Unknown site or organisation',
            N'The admission organisation or site identifier does not resolve to the governed reference data.',
            'PAS_ACTIVITY',
            'Admission',
            'REFERENCE',
            'ERROR',
            'QUARANTINED',
            'AEGIS-DQ-ADM-005',
            CONVERT(BIT, 1),
            CONVERT(BIT, 1)
        )
    ) AS [Source]
    (
        [ValidationRuleCode],
        [ValidationRuleVersion],
        [RuleName],
        [RuleDescription],
        [SourceDomain],
        [SourceObject],
        [RuleCategory],
        [Severity],
        [ExpectedOutcome],
        [ErrorCode],
        [IsReplayable],
        [IsActive]
    )
        ON  [Target].[ValidationRuleCode] = [Source].[ValidationRuleCode]
        AND [Target].[ValidationRuleVersion] = [Source].[ValidationRuleVersion]

    WHEN MATCHED AND
    (
           [Target].[RuleName] <> [Source].[RuleName]
        OR [Target].[RuleDescription] <> [Source].[RuleDescription]
        OR [Target].[SourceDomain] <> [Source].[SourceDomain]
        OR [Target].[SourceObject] <> [Source].[SourceObject]
        OR [Target].[RuleCategory] <> [Source].[RuleCategory]
        OR [Target].[Severity] <> [Source].[Severity]
        OR [Target].[ExpectedOutcome] <> [Source].[ExpectedOutcome]
        OR ISNULL([Target].[ErrorCode], '') <> ISNULL([Source].[ErrorCode], '')
        OR [Target].[IsReplayable] <> [Source].[IsReplayable]
        OR [Target].[IsActive] <> [Source].[IsActive]
    )
    THEN UPDATE SET
        [RuleName] = [Source].[RuleName],
        [RuleDescription] = [Source].[RuleDescription],
        [SourceDomain] = [Source].[SourceDomain],
        [SourceObject] = [Source].[SourceObject],
        [RuleCategory] = [Source].[RuleCategory],
        [Severity] = [Source].[Severity],
        [ExpectedOutcome] = [Source].[ExpectedOutcome],
        [ErrorCode] = [Source].[ErrorCode],
        [IsReplayable] = [Source].[IsReplayable],
        [IsActive] = [Source].[IsActive],
        [UpdatedAt] = SYSUTCDATETIME()

    WHEN NOT MATCHED BY TARGET
    THEN INSERT
    (
        [ValidationRuleCode],
        [ValidationRuleVersion],
        [RuleName],
        [RuleDescription],
        [SourceDomain],
        [SourceObject],
        [RuleCategory],
        [Severity],
        [ExpectedOutcome],
        [ErrorCode],
        [IsReplayable],
        [IsActive]
    )
    VALUES
    (
        [Source].[ValidationRuleCode],
        [Source].[ValidationRuleVersion],
        [Source].[RuleName],
        [Source].[RuleDescription],
        [Source].[SourceDomain],
        [Source].[SourceObject],
        [Source].[RuleCategory],
        [Source].[Severity],
        [Source].[ExpectedOutcome],
        [Source].[ErrorCode],
        [Source].[IsReplayable],
        [Source].[IsActive]
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
GO

:r .\Security\ConfigureAegisAdfLoader.sql
