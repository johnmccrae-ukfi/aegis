# High Availability and Disaster Recovery Strategy

## Purpose

Aegis includes SQL Server resilience patterns to demonstrate operational database engineering alongside data migration and reporting.

## Transactional replication

Transactional replication will copy selected source or operational tables from the primary SQL Server instance to a reporting subscriber.

### Objectives

- Offload reporting and extraction workloads.
- Demonstrate near-real-time data distribution.
- Monitor replication latency.
- Validate subscriber consistency.
- Practise publisher, distributor and subscriber administration.

### Proposed topology

```text
AEGISDEV
Publisher and Distributor
        │
        ▼
AEGISREPORT
Subscriber
```

## Log shipping

Log shipping will maintain a disaster-recovery copy of `Aegis_Warehouse`.

### Objectives

- Demonstrate transaction-log backup, copy and restore operations.
- Define recovery point and recovery time expectations.
- Monitor backup, copy and restore jobs.
- Perform a controlled recovery exercise.
- Document failover and failback considerations.

### Proposed topology

```text
AEGISDEV
Aegis_Warehouse primary
        │
        ▼
AEGISDR
Aegis_Warehouse_DR secondary
```

## Initial recovery objectives

The prototype will initially target:

- Recovery point objective: 15 minutes or less
- Recovery time objective: 30 minutes or less

These are demonstration objectives and not production NHS service commitments.

## Azure considerations

Azure SQL Database will be used as a separate portability and cloud demonstration target.

Azure-managed availability will not replace the local replication and log-shipping exercises because those exercises demonstrate traditional SQL Server administration skills required by the target roles.