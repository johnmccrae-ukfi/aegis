CREATE INDEX [IX_dq_ValidationRule_SourceObject_IsActive]
    ON [dq].[ValidationRule]
    (
        [SourceDomain],
        [SourceObject],
        [IsActive]
    )
    INCLUDE
    (
        [ValidationRuleCode],
        [ValidationRuleVersion],
        [RuleName],
        [Severity],
        [ExpectedOutcome]
    );
GO

CREATE INDEX [IX_dq_ValidationRule_ExpectedOutcome]
    ON [dq].[ValidationRule]
    (
        [ExpectedOutcome]
    )
    INCLUDE
    (
        [ValidationRuleCode],
        [SourceObject],
        [Severity],
        [IsActive]
    );