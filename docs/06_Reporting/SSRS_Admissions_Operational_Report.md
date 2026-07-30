# SSRS Admissions Operational Report

## Purpose

The Aegis SSRS Admissions report provides a focused operational view over the governed Admissions analytical layer.

It demonstrates how a validated SQL Server Analysis Services Tabular model can support parameter-driven SQL Server Reporting Services reporting while preserving migration reconciliation and operational transparency.

The implemented report is:

```text
Admissions Activity and Trends
```

The scope is deliberately limited to Admissions.

The report does not currently include:

- consultant episodes;
- diagnoses;
- procedures;
- ward stays;
- HL7 or FHIR processing;
- replay;
- replication;
- log shipping;
- Azure SQL;
- Microsoft Purview implementation.

---

## Reporting architecture

The report uses the deployed SSAS Tabular model:

```text
Aegis_Admissions_Analysis
```

The end-to-end reporting path is:

```text
Synthetic legacy PAS Admissions
        ↓
Audited SSIS ingestion
        ↓
landing.Admission
        ↓
stg.Admission
        ↓
accepted or quarantined
        ↓
curated.Admission
        ↓
reporting.AdmissionAnalysis
        ↓
Aegis_Admissions_Analysis
        ↓
SSRS Admissions Activity and Trends
```

The report consumes governed measures and dimensions from the semantic model rather than reproducing analytical calculations independently inside SSRS.

---

## SSRS solution and project

The SSRS solution is:

```text
src/ssrs/Aegis.Reporting/Aegis.Reporting.sln
```

The SSRS project is:

```text
src/ssrs/Aegis.Reporting/Aegis.Admissions.Reporting
```

The implemented report is:

```text
src/ssrs/Aegis.Reporting/Aegis.Admissions.Reporting/Reports/Admissions Activity and Trends.rdl
```

The shared Analysis Services data source is:

```text
src/ssrs/Aegis.Reporting/Aegis.Admissions.Reporting/Shared Data Sources/DS_Aegis_Admissions_Analysis.rds
```

---

## Shared data source

The report uses:

```text
Name:
DS_Aegis_Admissions_Analysis
```

```text
Type:
Microsoft SQL Server Analysis Services
```

```text
Server:
DESKTOP-N58JDOH
```

```text
Database:
Aegis_Admissions_Analysis
```

The development connection uses Windows integrated authentication.

No passwords or private credentials are stored in Git.

---

## Report structure

The report contains four principal sections:

```text
Admissions Activity and Trends
├── KPI summary
├── monthly Admissions and discharge trend
├── organisation parameter
└── site activity table
```

### KPI summary

The report displays six governed semantic-model measures:

```text
Admissions
Open Admissions
Discharged Admissions
Distinct Patients
Average Completed Length of Stay
Open Admission Percentage
```

The validated unfiltered baseline is:

| Measure | Value |
|---|---:|
| Admissions | 1,600 |
| Open Admissions | 192 |
| Discharged Admissions | 1,408 |
| Distinct Patients | 708 |
| Average Completed Length of Stay | 7.43 days |
| Open Admission Percentage | 12.00% |

The KPI cards are hosted within a List data region bound to the KPI dataset.

This provides the required SSRS dataset context while allowing the report to use multiple datasets.

---

## Monthly activity trend

The report includes a line chart showing:

```text
Admissions
Discharged Admissions
```

by:

```text
Dim Date[Year Month]
```

The Admission series uses the active relationship between:

```text
Dim Date[Date]
        ↓
Fact Admission[AdmissionDate]
```

The discharge series uses the deployed measure:

```text
Discharged Admissions
```

which activates the inactive relationship between:

```text
Dim Date[Date]
        ↓
Fact Admission[DischargeDate]
```

through DAX `USERELATIONSHIP`.

The chart excludes the semantic-model blank date member.

### July 2026 profile

The visible July 2026 increase is intentional and reflects the synthetic reporting cut-off.

Validated July 2026 activity includes:

```text
Admissions:              203
Open Admissions:         192
Discharged Admissions:    18
```

The report includes a parameter-safe explanatory note:

```text
The July 2026 increase reflects the synthetic reporting cut-off, with a substantial proportion of recently recorded Admissions remaining open.
```

---

## Organisation parameter

The report includes a single-select parameter:

```text
Organisation
```

The parameter provides:

```text
All Organisations
Aegis Integrated Care Services
Aegis University Hospitals NHS Trust
North Aegis Community Health Partnership
```

The default value is:

```text
All Organisations
```

The parameter dataset returns separate values and labels:

```text
OrganisationValue
OrganisationLabel
```

The synthetic value:

```text
__ALL__
```

represents the unfiltered report state.

The organisation parameter controls:

- KPI cards;
- monthly Admissions and discharge chart;
- site activity table.

---

## Site activity table

The report includes an organisation-aware site table with:

```text
Site
Admissions
Open
Discharged
```

The complete unfiltered site reconciliation is:

| Site | Admissions | Open | Discharged |
|---|---:|---:|---:|
| Aegis Women and Children Centre | 300 | 47 | 253 |
| Aegis Community Hospital | 321 | 37 | 284 |
| Aegis General Hospital | 334 | 38 | 296 |
| Aegis Diagnostic Centre | 331 | 37 | 294 |
| North Aegis Hospital | 314 | 33 | 281 |
| **Total** | **1,600** | **192** | **1,408** |

The site table uses a Tablix filter so that:

```text
All Organisations
        ↓
all five sites
```

and:

```text
specific organisation
        ↓
only associated sites
```

For example:

```text
Aegis University Hospitals NHS Trust
        ↓
Aegis Community Hospital
Aegis General Hospital
```

Its validated totals are:

```text
Admissions:              655
Open Admissions:          75
Discharged Admissions:   580
```

---

## Embedded datasets

The report contains the following embedded datasets:

```text
DS_KPI_Summary
DS_Monthly_Activity
DS_Organisation_Site_Activity
DS_Organisation_Parameter
```

### `DS_KPI_Summary`

Purpose:

- returns one governed KPI row;
- responds to the organisation parameter;
- feeds the six KPI cards.

### `DS_Monthly_Activity`

Purpose:

- returns Year-Month activity;
- provides Admissions and discharge series;
- responds to the organisation parameter;
- excludes the blank Year-Month member.

### `DS_Organisation_Site_Activity`

Purpose:

- returns organisation and site activity;
- remains an unfiltered five-row dataset;
- is filtered at the Tablix level using the report parameter.

### `DS_Organisation_Parameter`

Purpose:

- supplies the organisation dropdown;
- includes the synthetic `All Organisations` option;
- separates displayed labels from submitted values.

---

## SSRS design decisions

### One polished report

The initial Day 5 plan considered three reports:

```text
Admissions Activity and Trends
Open Admissions and Length of Stay
Migration Reconciliation and Data Quality
```

The implemented release deliberately contains one complete, polished and interactive report.

This was chosen because it provides stronger portfolio evidence than several partially completed reports.

The deferred report concepts remain suitable future extensions.

### SSAS-backed analysis

Analytical calculations remain governed in SSAS.

SSRS provides:

- paginated presentation;
- parameters;
- data-region filtering;
- deployment;
- export;
- operational consumption.

### Dataset-specific data regions

SSRS requires explicit dataset context when a report contains multiple datasets.

The KPI cards therefore use a List data region bound to:

```text
DS_KPI_Summary
```

The chart uses:

```text
DS_Monthly_Activity
```

The site table uses:

```text
DS_Organisation_Site_Activity
```

### Table-level organisation filtering

The site dataset contains only five rows.

Filtering the Tablix rather than parameterising the SSAS query avoids unnecessary complexity and preserves the `All Organisations` option reliably.

---

## Layout and export design

The report uses A4 landscape dimensions:

```text
Page width:   29.7 cm
Page height:  21.0 cm
Margins:       1.0 cm
```

The report body width is:

```text
27.5 cm
```

This leaves a small export tolerance and avoids unwanted blank PDF pages caused by width rounding.

The report renders on a single page.

---

## Build and deployment

The SSRS project builds successfully:

```text
Build: 1 succeeded or up-to-date
Failed: 0
Skipped: 0
```

The project deploys successfully:

```text
Deploy: 1 succeeded
Failed: 0
Skipped: 0
```

Deployment target:

```text
http://localhost/reportserver
```

Deployment path:

```text
Aegis
└── Admissions
    └── Admissions Activity and Trends
```

The deployed report is available through the SSRS web portal:

```text
http://localhost/Reports
```

---

## Deployment validation

The deployed report was validated in the SSRS portal with no credential prompt or data-source error.

### All Organisations

Validated values:

```text
Admissions:                         1,600
Open Admissions:                      192
Discharged Admissions:              1,408
Distinct Patients:                    708
Average Completed Length of Stay:    7.43 days
Open Admission Percentage:          12.00%
Site rows:                               5
```

### Aegis University Hospitals NHS Trust

Validated values:

```text
Admissions:                         655
Open Admissions:                     75
Discharged Admissions:              580
Distinct Patients:                  447
Average Completed Length of Stay:   7.38 days
Open Admission Percentage:         11.45%
Site rows:                            2
```

The filtered site totals reconcile exactly with the filtered KPI totals.

---

## Visual evidence

The deployed SSRS report screenshot is:

```text
images/ssrs/aegis_ssrs_admissions_activity_and_trends.png
```

The image demonstrates:

- deployment in the SSRS web portal;
- organisation parameter;
- governed KPI measures;
- monthly activity trend;
- site-level activity;
- the validated all-organisation baseline.

---

## SSRS implementation lessons

The implementation demonstrated several practical SSRS behaviours:

- a List is implemented as a Tablix containing an internal Rectangle;
- standalone textboxes require explicit dataset context when multiple datasets exist;
- report-item containment is often best established using cut and paste;
- Tablix row height directly affects pagination;
- Analysis Services graphical query metadata can be cached;
- query fields may need manual refresh or replacement;
- generated SSAS parameters may behave differently from relational query parameters;
- a report parameter can control datasets and data-region filters together;
- body width and page margins require export tolerance.

These behaviours are important practical knowledge for maintaining established SSRS estates.

---

## Deferred enhancements

Possible later additions include:

- Open Admissions and Length of Stay report;
- Migration Reconciliation and Data Quality report;
- quarantined Admission detail;
- batch and package execution detail;
- validation-rule exception summaries;
- source-to-curated drill-through;
- admission and discharge date parameters;
- site parameter cascading from organisation;
- scheduled report subscriptions;
- role-based report security;
- Power BI paginated report migration.

These enhancements are deferred so the current release remains focused and complete.

---

## Final status

```text
SSRS project build:                  SUCCEEDED
SSRS project deployment:             SUCCEEDED
Deployed report validation:          PASSED
All-organisation reconciliation:     PASSED
Organisation filtering:              PASSED
Site-level reconciliation:           PASSED
Single-page rendering:                PASSED
```

The Admissions Activity and Trends report completes the focused Aegis Admissions delivery path:

```text
Synthetic PAS
        ↓
Audited SSIS
        ↓
Accepted or quarantined
        ↓
Governed reporting view
        ↓
SSAS Tabular model
        ↓
SSRS operational report
```