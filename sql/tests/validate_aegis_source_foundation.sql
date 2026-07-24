USE [Aegis_Source];
GO

SET NOCOUNT ON;

DECLARE @ValidationResults TABLE
(
    CheckName VARCHAR(100) NOT NULL,
    Passed    BIT          NOT NULL,
    Detail    NVARCHAR(500) NULL
);

-- Existing schema and pas.Patient checks

INSERT INTO @ValidationResults
(
    CheckName,
    Passed,
    Detail
)
SELECT
    'pas schema exists',
    CASE WHEN SCHEMA_ID(N'pas') IS NOT NULL THEN 1 ELSE 0 END,
    N'Expected schema: pas';

-- All remaining table checks
-- All new reference-table checks
-- All foreign-key checks

SELECT
    CheckName,
    Passed,
    Detail
FROM @ValidationResults
ORDER BY CheckName;

IF EXISTS
(
    SELECT 1
    FROM @ValidationResults
    WHERE Passed = 0
)
BEGIN
    THROW 51000, 'Aegis source foundation validation failed.', 1;
END;

PRINT 'Aegis source foundation validation passed.';
GO