CREATE INDEX [IX_audit_RecordOutcome_PackageExecutionId]
    ON [audit].[RecordOutcome]
    (
        [PackageExecutionId],
        [ProcessedAt]
    );
GO

CREATE INDEX [IX_audit_RecordOutcome_BatchId_ProcessingOutcome]
    ON [audit].[RecordOutcome]
    (
        [BatchId],
        [ProcessingOutcome]
    )
    INCLUDE
    (
        [SourceDomain],
        [SourceObject],
        [SourceRecordIdentifier],
        [ProcessedAt]
    );
GO

CREATE INDEX [IX_audit_RecordOutcome_SourceObject]
    ON [audit].[RecordOutcome]
    (
        [SourceDomain],
        [SourceObject]
    )
    INCLUDE
    (
        [BatchId],
        [ProcessingOutcome],
        [ProcessedAt]
    );