-- ============================================================
-- PROJECT  : Credit Risk Analysis — Loan Default Prediction
-- FILE     : 01_eda_queries.sql
-- AUTHOR   : Aasim Ahmed | MS Computer Science | Data Analyst
-- PURPOSE  : Exploratory Data Analysis on raw loan dataset
-- DATASET  : credit_train.csv | 100,514 records | 19 columns
-- ============================================================


-- ============================================================
-- SECTION 0 — DATASET OVERVIEW
-- ============================================================

-- Q0.1: How many records and what is the overall shape?
SELECT COUNT(*) AS Total_Records
FROM credit_train;
-- Result: 100,514 rows

-- Q0.2: Preview first 10 rows
SELECT TOP 10 *
FROM credit_train;

-- Q0.3: Column names and data types
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'credit_train'
ORDER BY ORDINAL_POSITION;


-- ============================================================
-- SECTION 1 — TARGET VARIABLE DISTRIBUTION
-- ============================================================

-- Q1.1: How many loans are Fully Paid vs Charged Off?
SELECT 
    Loan_Status,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS Percentage
FROM credit_train
GROUP BY Loan_Status;
-- Result: Fully Paid ~77.4% | Charged Off ~22.6%


-- ============================================================
-- SECTION 2 — CREDIT SCORE ANALYSIS
-- ============================================================

-- Q2.1: Average credit score by loan status
SELECT 
    Loan_Status,
    ROUND(AVG(CAST(Credit_Score AS FLOAT)), 2)  AS Avg_Credit_Score,
    MIN(Credit_Score)  AS Min_Credit_Score,
    MAX(Credit_Score)  AS Max_Credit_Score
FROM credit_train
WHERE Credit_Score IS NOT NULL
GROUP BY Loan_Status;
-- Finding: Only 3-point gap (718.6 vs 715.4) — weak predictor

-- Q2.2: Detect impossible credit scores 
SELECT COUNT(*) AS Invalid_Credit_Scores
FROM credit_train
WHERE Credit_Score > 850;
-- Finding: Corrupt values found — flagged for cleaning


-- ============================================================
-- SECTION 3 — ANNUAL INCOME ANALYSIS
-- ============================================================

-- Q3.1: Average income by loan status
SELECT 
    Loan_Status,
    ROUND(AVG(CAST(Annual_Income AS FLOAT)), 0)  AS Avg_Annual_Income,
    ROUND(MIN(CAST(Annual_Income AS FLOAT)), 0)  AS Min_Income,
    ROUND(MAX(CAST(Annual_Income AS FLOAT)), 0)  AS Max_Income
FROM credit_train
WHERE Annual_Income IS NOT NULL
GROUP BY Loan_Status;
-- Finding: $121K income gap — defaulters earn significantly less

-- Q3.2: Check for missing income values
SELECT COUNT(*) AS Missing_Income
FROM credit_train
WHERE Annual_Income IS NULL;


-- ============================================================
-- SECTION 4 — LOAN TERM ANALYSIS
-- ============================================================

-- Q4.1: Default rate by loan term
SELECT 
    Term,
    COUNT(*) AS Total_Loans,
    SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END) AS Total_Defaults,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS Default_Rate_Pct
FROM credit_train
GROUP BY Term
ORDER BY Default_Rate_Pct DESC;
-- Finding: Long Term 30.1% vs Short Term 19.8% — 52% higher risk


-- ============================================================
-- SECTION 5 — LOAN PURPOSE ANALYSIS
-- ============================================================

-- Q5.1: Default rate by loan purpose (ranked highest to lowest)
SELECT 
    Purpose,
    COUNT(*) AS Total_Loans,
    SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END) AS Total_Defaults,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS Default_Rate_Pct
FROM credit_train
GROUP BY Purpose
ORDER BY Default_Rate_Pct DESC;
-- Finding: Business Loan 32.24% | Renewable Energy 40% | Buy a Car 16.05%

-- Q5.2: Volume + default rate together 
SELECT 
    Purpose,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS Portfolio_Share_Pct,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )  AS Default_Rate_Pct
FROM credit_train
GROUP BY Purpose
ORDER BY Total_Loans DESC;
-- Finding: Debt Consolidation = 78% of portfolio at 22.81% default rate


-- ============================================================
-- SECTION 6 — HOME OWNERSHIP ANALYSIS
-- ============================================================

-- Q6.1: Default rate by home ownership type
SELECT 
    Home_Ownership,
    COUNT(*) AS Total_Loans,
    SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END) AS Total_Defaults,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS Default_Rate_Pct
FROM credit_train
GROUP BY Home_Ownership
ORDER BY Default_Rate_Pct DESC;
-- Finding: Rent 25.11% > Own Home 22.89% > Home Mortgage 20.44%


-- ============================================================
-- SECTION 7 — EMPLOYMENT ANALYSIS
-- ============================================================

-- Q7.1: Default rate by years in current job
SELECT 
    Years_in_current_job,
    COUNT(*) AS Total_Loans,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS Default_Rate_Pct
FROM credit_train
GROUP BY Years_in_current_job
ORDER BY Default_Rate_Pct DESC;
-- Finding: 'n/a' group has 30.1% default — unknown employment = high risk


-- ============================================================
-- SECTION 8 — DATA QUALITY CHECKS
-- ============================================================

-- Q8.1: Count all NULL values per column
SELECT
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS Null_CustomerID,
    SUM(CASE WHEN Loan_Status IS NULL THEN 1 ELSE 0 END) AS Null_LoanStatus,
    SUM(CASE WHEN Current_Loan_Amount IS NULL THEN 1 ELSE 0 END) AS Null_LoanAmount,
    SUM(CASE WHEN Credit_Score IS NULL THEN 1 ELSE 0 END) AS Null_CreditScore,
    SUM(CASE WHEN Annual_Income IS NULL THEN 1 ELSE 0 END) AS Null_AnnualIncome,
    SUM(CASE WHEN Years_in_current_job IS NULL THEN 1 ELSE 0 END) AS Null_YearsInJob,
    SUM(CASE WHEN Home_Ownership IS NULL THEN 1 ELSE 0 END) AS Null_HomeOwnership,
    SUM(CASE WHEN Purpose IS NULL THEN 1 ELSE 0 END) AS Null_Purpose,
    SUM(CASE WHEN Monthly_Debt IS NULL THEN 1 ELSE 0 END) AS Null_MonthlyDebt,
    SUM(CASE WHEN Bankruptcies IS NULL THEN 1 ELSE 0 END) AS Null_Bankruptcies
FROM credit_train;

-- Q8.2: Detect corrupt loan amount placeholder (99999999)
SELECT COUNT(*) AS Corrupt_Loan_Amounts
FROM credit_train
WHERE Current_Loan_Amount = 99999999;
-- Finding: 11,484 rows with placeholder value — flagged for cleaning

-- Q8.3: Check for fully empty/duplicate rows
SELECT 
    Customer_ID,
    COUNT(*) AS Row_Count
FROM credit_train
GROUP BY Customer_ID
HAVING COUNT(*) > 1
ORDER BY Row_Count DESC;

-- Q8.4: Detect inconsistent category labels in Home_Ownership
SELECT DISTINCT Home_Ownership
FROM credit_train
ORDER BY Home_Ownership;
-- Finding: 'HaveMortgage' and 'Home Mortgage' both exist — need standardization

-- Q8.5: Detect inconsistent category labels in Purpose
SELECT DISTINCT Purpose
FROM credit_train
ORDER BY Purpose;
-- Finding: 'small_business' vs 'Business Loan', 'other' vs 'Other' etc.

-- Q8.6: Check for 'n/a' stored as text string (not NULL)
SELECT COUNT(*) AS Text_NA_Count
FROM credit_train
WHERE Years_in_current_job = 'n/a';
-- Finding: 4,222 rows with 'n/a' as text — needs conversion to NULL


-- ============================================================
-- SECTION 9 — BANKRUPTCY & DELINQUENCY ANALYSIS
-- ============================================================

-- Q9.1: Default rate by number of bankruptcies
SELECT 
    Bankruptcies,
    COUNT(*)  AS Total_Loans,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )  AS Default_Rate_Pct
FROM credit_train
WHERE Bankruptcies IS NOT NULL
GROUP BY Bankruptcies
ORDER BY Bankruptcies;
-- Finding: Bankruptcies showed no meaningful correlation — surprising result


-- ============================================================
-- END OF EDA
-- ============================================================
