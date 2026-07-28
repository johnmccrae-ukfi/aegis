CREATE INDEX [IX_dq_DataQualityException_BatchId]
    ON [dq].[DataQualityException]
    (
        [BatchId],
        [CreatedAt]
    )
    INCLUDE
    (
        [ValidationRuleId],
        [SourceObject],
        [SourceRecordIdentifier],
        [ResolutionStatus]
    );
GO

CREATE INDEX [IX_dq_DataQualityException_PackageExecutionId]
    ON [dq].[DataQualityException]
    (
        [PackageExecutionId],
        [CreatedAt]
    );
GO

CREATE INDEX [IX_dq_DataQualityException_ValidationRuleId]
    ON [dq].[DataQualityException]
    (
        [ValidationRuleId],
        [ResolutionStatus]
    )
    INCLUDE
    (
        [BatchId],
        [SourceObject],
        [SourceRecordIdentifier],
        [CreatedAt]
    );
GO

CREATE INDEX [IX_dq_DataQualityException_ResolutionStatus]
    ON [dq].[DataQualityException]
    (
        [ResolutionStatus]
    )
    INCLUDE
    (
        [BatchId],
        [ValidationRuleId],
        [SourceObject],
        [CreatedAt],
        [ResolvedAt]
    );