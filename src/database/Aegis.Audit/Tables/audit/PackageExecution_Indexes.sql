CREATE INDEX [IX_audit_PackageExecution_BatchId]
    ON [audit].[PackageExecution]
    (
        [BatchId],
        [StartedAt]
    );
GO

CREATE INDEX [IX_audit_PackageExecution_ExecutionStatus]
    ON [audit].[PackageExecution]
    (
        [ExecutionStatus]
    )
    INCLUDE
    (
        [BatchId],
        [PackageName],
        [StartedAt],
        [CompletedAt]
    );
GO

CREATE UNIQUE INDEX [UX_audit_PackageExecution_SsisExecutionId]
    ON [audit].[PackageExecution]
    (
        [SsisExecutionId]
    )
    WHERE [SsisExecutionId] IS NOT NULL;