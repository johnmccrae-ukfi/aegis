CREATE INDEX [IX_audit_Batch_InterfaceId_ReceivedAt]
    ON [audit].[Batch]
    (
        [InterfaceId],
        [ReceivedAt]
    );
GO

CREATE INDEX [IX_audit_Batch_BatchStatus]
    ON [audit].[Batch]
    (
        [BatchStatus]
    )
    INCLUDE
    (
        [InterfaceId],
        [ReceivedAt],
        [StartedAt],
        [CompletedAt]
    );
GO

CREATE INDEX [IX_audit_Batch_ParentBatchId]
    ON [audit].[Batch]
    (
        [ParentBatchId]
    )
    WHERE [ParentBatchId] IS NOT NULL;