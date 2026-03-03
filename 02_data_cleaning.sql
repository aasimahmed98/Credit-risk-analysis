-- ============================================================
-- PROJECT  : Credit Risk Analysis — Loan Default Prediction
-- FILE     : 02_data_cleaning.sql
-- AUTHOR   : Aasim Ahmed | MS Computer Science | Data Analyst
-- PURPOSE  : Data cleaning and transformation pipeline
-- INPUT    : credit_train        (raw | 100,514 rows)
-- OUTPUT   : credit_train_clean  (clean | 100,000 rows)
-- ============================================================
-- CLEANING STEPS:
--   1. Create clean copy of raw table
--   2. Null out corrupt loan amounts (99999999 placeholder)
--   3. Null out impossible credit scores (> 850)
--   4. Standardize Home Ownership labels
--   5. Standardize Loan Purpose labels
--   6. Convert 'n/a' text to NULL in Years_in_current_job
--   7. Impute missing Credit Score and Annual Income with median
--   8. Delete fully empty rows
--   9. Final validation
-- ============================================================


-- ============================================================
-- STEP 1 — CREATE CLEAN COPY OF RAW TABLE
-- ============================================================

-- Drop if exists from previous run
DROP TABLE IF EXISTS credit_train_clean;

-- Create clean working copy
SELECT *
INTO credit_train_clean
FROM credit_train;

-- Verify copy
SELECT COUNT(*) AS Rows_After_Copy FROM credit_train_clean;
-- Expected: 100,514


-- ============================================================
-- STEP 2 — NULL OUT CORRUPT LOAN AMOUNTS
-- ============================================================
-- Issue: 11,484 rows have Current_Loan_Amount = 99999999
-- This is clearly a system placeholder, not a real value
-- Fix: Replace with NULL so it can be excluded from analysis

UPDATE credit_train_clean
SET Current_Loan_Amount = NULL
WHERE Current_Loan_Amount = 99999999;

-- Verify
SELECT COUNT(*) AS Corrupt_Amounts_Remaining
FROM credit_train_clean
WHERE Current_Loan_Amount = 99999999;
-- Expected: 0


-- ============================================================
-- STEP 3 — NULL OUT IMPOSSIBLE CREDIT SCORES
-- ============================================================
-- Issue: Credit scores above 850 are not possible (max FICO = 850)
-- Fix: Set to NULL — do not impute yet (handled in Step 7)

UPDATE credit_train_clean
SET Credit_Score = NULL
WHERE Credit_Score > 850;

-- Verify max score is now valid
SELECT MAX(Credit_Score) AS Max_Credit_Score
FROM credit_train_clean;
-- Expected: <= 850


-- ============================================================
-- STEP 4 — STANDARDIZE HOME OWNERSHIP LABELS
-- ============================================================
-- Issue: 'HaveMortgage' and 'Home Mortgage' represent the same category
-- Fix: Merge HaveMortgage → Home Mortgage

UPDATE credit_train_clean
SET Home_Ownership = 'Home Mortgage'
WHERE Home_Ownership = 'HaveMortgage';

-- Verify distinct values
SELECT DISTINCT Home_Ownership
FROM credit_train_clean
ORDER BY Home_Ownership;
-- Expected: Home Mortgage | Own Home | Rent


-- ============================================================
-- STEP 5 — STANDARDIZE LOAN PURPOSE LABELS
-- ============================================================
-- Issue: Multiple inconsistent labels for same categories
-- Fix: Merge all variants into clean standard labels

-- 5a. Merge 'other' → 'Other' (case inconsistency)
UPDATE credit_train_clean
SET Purpose = 'Other'
WHERE Purpose = 'other';

-- 5b. Merge 'small_business' → 'Business Loan'
UPDATE credit_train_clean
SET Purpose = 'Business Loan'
WHERE Purpose = 'small_business';

-- 5c. Standardize remaining snake_case labels
UPDATE credit_train_clean
SET Purpose = 'Major Purchase'
WHERE Purpose = 'major_purchase';

UPDATE credit_train_clean
SET Purpose = 'Moving'
WHERE Purpose = 'moving';

UPDATE credit_train_clean
SET Purpose = 'Vacation'
WHERE Purpose = 'vacation';

UPDATE credit_train_clean
SET Purpose = 'Wedding'
WHERE Purpose = 'wedding';

UPDATE credit_train_clean
SET Purpose = 'Renewable Energy'
WHERE Purpose = 'renewable_energy';

-- Verify all distinct purpose values
SELECT 
    Purpose,
    COUNT(*) AS Total_Loans
FROM credit_train_clean
GROUP BY Purpose
ORDER BY Total_Loans DESC;


-- ============================================================
-- STEP 6 — CONVERT 'n/a' TEXT TO NULL
-- ============================================================
-- Issue: 4,222 rows have the string 'n/a' in Years_in_current_job
-- This is stored as text, not a true NULL
-- Fix: Convert to proper NULL for accurate analysis

UPDATE credit_train_clean
SET Years_in_current_job = NULL
WHERE Years_in_current_job = 'n/a';

-- Verify
SELECT COUNT(*) AS Text_NA_Remaining
FROM credit_train_clean
WHERE Years_in_current_job = 'n/a';
-- Expected: 0


-- ============================================================
-- STEP 7 — IMPUTE MISSING CREDIT SCORE AND ANNUAL INCOME
-- ============================================================
-- Issue: 19,668 rows missing both Credit_Score and Annual_Income
-- Strategy: Impute with median (more robust than mean for skewed data)
-- Using PERCENTILE_CONT(0.5) for true median calculation

-- 7a. Impute missing Credit Score with median
UPDATE credit_train_clean
SET Credit_Score = (
    SELECT PERCENTILE_CONT(0.5) 
    WITHIN GROUP (ORDER BY Credit_Score)
    OVER ()
    FROM credit_train_clean
    WHERE Credit_Score IS NOT NULL
    FETCH FIRST 1 ROWS ONLY
)
WHERE Credit_Score IS NULL;

-- Alternative syntax for SQL Server:
UPDATE credit_train_clean
SET Credit_Score = (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Credit_Score)
        OVER ()
    FROM credit_train_clean
    WHERE Credit_Score IS NOT NULL
)
WHERE Credit_Score IS NULL;

-- 7b. Impute missing Annual Income with median
UPDATE credit_train_clean
SET Annual_Income = (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Annual_Income AS FLOAT))
        OVER ()
    FROM credit_train_clean
    WHERE Annual_Income IS NOT NULL
)
WHERE Annual_Income IS NULL;

-- Verify no nulls remain
SELECT 
    SUM(CASE WHEN Credit_Score   IS NULL THEN 1 ELSE 0 END) AS Null_CreditScore,
    SUM(CASE WHEN Annual_Income  IS NULL THEN 1 ELSE 0 END) AS Null_AnnualIncome
FROM credit_train_clean;
-- Expected: 0 | 0


-- ============================================================
-- STEP 8 — DELETE FULLY EMPTY ROWS
-- ============================================================
-- Issue: 514 rows where all key fields are NULL
-- These carry no analytical value and should be removed

DELETE FROM credit_train_clean
WHERE 
    Loan_Status           IS NULL
    AND Current_Loan_Amount IS NULL
    AND Credit_Score        IS NULL
    AND Annual_Income       IS NULL
    AND Purpose             IS NULL
    AND Home_Ownership      IS NULL;

-- Verify row count after deletion
SELECT COUNT(*) AS Rows_After_Cleaning
FROM credit_train_clean;
-- Expected: 100,000


-- ============================================================
-- STEP 9 — FINAL VALIDATION
-- ============================================================

-- 9a. Final row count
SELECT COUNT(*) AS Final_Row_Count
FROM credit_train_clean;
-- Expected: 100,000

-- 9b. Check no nulls remain in critical columns
SELECT
    SUM(CASE WHEN Loan_Status         IS NULL THEN 1 ELSE 0 END) AS Null_LoanStatus,
    SUM(CASE WHEN Credit_Score        IS NULL THEN 1 ELSE 0 END) AS Null_CreditScore,
    SUM(CASE WHEN Annual_Income       IS NULL THEN 1 ELSE 0 END) AS Null_AnnualIncome,
    SUM(CASE WHEN Home_Ownership      IS NULL THEN 1 ELSE 0 END) AS Null_HomeOwnership,
    SUM(CASE WHEN Purpose             IS NULL THEN 1 ELSE 0 END) AS Null_Purpose,
    SUM(CASE WHEN Term                IS NULL THEN 1 ELSE 0 END) AS Null_Term
FROM credit_train_clean;
-- Expected: all 0s

-- 9c. Confirm credit score range is valid
SELECT 
    MIN(Credit_Score) AS Min_Score,
    MAX(Credit_Score) AS Max_Score
FROM credit_train_clean;
-- Expected: Min > 300 | Max <= 850

-- 9d. Confirm no corrupt loan amounts remain
SELECT COUNT(*) AS Corrupt_Remaining
FROM credit_train_clean
WHERE Current_Loan_Amount = 99999999;
-- Expected: 0

-- 9e. Confirm purpose labels are clean
SELECT DISTINCT Purpose
FROM credit_train_clean
ORDER BY Purpose;
-- Expected: No snake_case, no duplicates

-- 9f. Confirm home ownership labels are clean
SELECT DISTINCT Home_Ownership
FROM credit_train_clean
ORDER BY Home_Ownership;
-- Expected: Home Mortgage | Own Home | Rent

-- 9g. Final default rate on clean dataset
SELECT 
    Loan_Status,
    COUNT(*)                                            AS Total_Loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2)  AS Percentage
FROM credit_train_clean
GROUP BY Loan_Status;
-- Expected: Fully Paid ~77.36% | Charged Off ~22.64%

-- ============================================================
-- CLEANING COMPLETE
-- Output table: credit_train_clean
-- Rows: 100,000
-- Ready for: Tableau visualization and further analysis
-- ============================================================
