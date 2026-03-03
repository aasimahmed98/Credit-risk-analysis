# 📊 Credit Risk Analysis — Loan Default Prediction

> **End-to-end data analytics project** analyzing 100,000 loan records to identify key drivers of loan default and simulate business impact of risk mitigation strategies.

---

## 🏆 Project Highlights

| Metric | Value |
|--------|-------|
| 📁 Dataset Size | 100,000 loans (after cleaning) |
| 🔴 Default Rate | 22.64% (22,639 defaults) |
| 🛠️ Tools Used | SQL Server · Tableau Public · Excel |
| 📈 Key Finding | Loan purpose & term length are strongest default predictors |
| 💰 Projected Savings | Up to **$15.7M** if recommendations implemented |

---

## 🛠️ Tools & Technologies

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)

---

## 📁 Project Structure

```
credit-risk-analysis/
│
├── 📂 sql/
│   ├── 01_eda_queries.sql          # Exploratory data analysis queries
│   └── 02_data_cleaning.sql        # Data cleaning & transformation
│
├── 📂 presentation/
│   └── Credit_Risk_Analysis.pptx  # Full consulting-style slide deck (9 slides)
│
├── 📂 visualizations/
│   └── dashboard_screenshot.png   # Tableau dashboard screenshot
│
└── README.md
```

---

## 🔄 Project Workflow

```
Raw Data (100,514 rows)
       ↓
  1. EDA with SQL          → 12 queries to profile data, find patterns
       ↓
  2. Data Cleaning (SQL)   → Remove nulls, fix corrupt values, standardize categories
       ↓
  3. Clean Dataset         → 100,000 rows, ready for analysis
       ↓
  4. Tableau Dashboard     → 5 charts + 4 KPI metrics
       ↓
  5. PowerPoint Deck       → 9 consulting-style slides with business recommendations
```

---

## 🔍 Step 1 — Exploratory Data Analysis (SQL)

Performed 12 SQL queries to understand the data:

```sql
-- Default rate by loan purpose
SELECT 
    Purpose,
    COUNT(*) AS Total_Loans,
    SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END) AS Defaults,
    ROUND(
        100.0 * SUM(CASE WHEN Loan_Status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS Default_Rate_Pct
FROM credit_train
GROUP BY Purpose
ORDER BY Default_Rate_Pct DESC;
```

**Key EDA Findings:**
- 🔴 Business loans default at **32.24%** — highest among all purposes
- ⏱️ Long-term loans default at **30.1%** vs 19.8% for short-term — **52% higher risk**
- 🏠 Renters default at **25.11%** vs 20.44% for mortgage holders
- 💳 Credit score gap between defaulters and non-defaulters: only **3 points** (weak predictor)
- 💵 Income gap: defaulters earn **$121K less** annually

---

## 🧹 Step 2 — Data Cleaning (SQL)

| Issue Found | Fix Applied | Rows Affected |
|---|---|---|
| Placeholder loan amounts (99999999) | Set to NULL | 11,484 |
| Credit scores above 850 (impossible) | Set to NULL | ~200 |
| Inconsistent category labels | Standardized (e.g. `small_business` → `Business Loan`) | 7 fields |
| `n/a` stored as text in Years in Job | Converted to NULL | 4,222 |
| Missing Credit Score & Income | Imputed with median using `PERCENTILE_CONT` | 19,668 |
| Fully empty rows | Deleted | 514 |

```sql
-- Example: Impute missing Credit Score with median
UPDATE credit_train_clean
SET Credit_Score = (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Credit_Score)
    FROM credit_train_clean
    WHERE Credit_Score IS NOT NULL
)
WHERE Credit_Score IS NULL;
```

---

## 📊 Step 3 — Tableau Dashboard

**Dashboard includes:**
- 🔴 Default Rate by Loan Purpose (heat-colored bar chart)
- 📊 Default Rate by Loan Term
- 🏠 Default Rate by Home Ownership
- 💳 Average Credit Score by Loan Status
- 💵 Average Annual Income by Loan Status
- 4 KPI cards: Total Loans · Total Defaults · Default Rate · Avg Defaulter Income

> 📸 See `/visualizations/dashboard_screenshot.png`

---

## 📈 Key Findings

### 1. Loan Purpose is the Strongest Predictor
| Purpose | Default Rate |
|---|---|
| Renewable Energy | 40.00% 🔴 |
| Business Loan | 32.24% 🔴 |
| Vacation | 28.71% 🟠 |
| Debt Consolidation | 22.81% 🟡 |
| Home Improvements | 19.92% 🟢 |
| Buy a Car | 16.05% 🟢 |

### 2. Loan Term is a Critical Risk Signal
- **Long Term:** 30.1% default rate
- **Short Term:** 19.8% default rate
- Long-term loans are **52% riskier**

### 3. Income Gap Matters
- Fully Paid avg income: **$1.37M**
- Charged Off avg income: **$1.25M**
- Gap: **$121,306** — defaulters earn 9% less

### 4. Credit Score is a Weak Predictor
- Fully Paid avg score: **718.6**
- Charged Off avg score: **715.4**
- Only a 3-point gap — **credit score alone is insufficient for risk assessment**

---

## 💡 Recommendations

| Priority | Action | Expected Impact |
|---|---|---|
| 🔴 HIGH | Tighten business loan criteria — require collateral & co-signers | Reduce business loan defaults |
| 🔴 HIGH | Apply stricter income thresholds for long-term loans | Reduce long-term default rate |
| 🟡 MEDIUM | Weight income more heavily in credit scoring model | Earlier detection of high-risk applicants |
| 🟡 MEDIUM | Apply risk premium pricing for renters | Offset higher default risk |

---

## 💰 Business Impact Simulation

| Scenario | Action | Default Reduction | Estimated Savings |
|---|---|---|---|
| 1 | Reduce long-term loan exposure by 15% | −1,246 defaults | **$6.2M** |
| 2 | Reject top 20% riskiest business loans | −892 defaults | **$4.5M** |
| 3 | Both policies combined | −3,140 defaults | **$15.7M** |

> *Projections based on historical default rates. Avg loss per default estimated at $5,000.*

---

## 🚀 How to Run

### SQL (EDA & Cleaning)
1. Import `data/credit_train.csv` into SQL Server Management Studio
2. Run `sql/01_eda_queries.sql` for exploratory analysis
3. Run `sql/02_data_cleaning.sql` to create the clean dataset

### Tableau Dashboard
1. Connect Tableau Public to the cleaned CSV export
2. Open the workbook or recreate using the dashboard screenshot as reference

---

## 👤 About

**Aasim Ahmed**
MS Computer Science | Data Analyst

This project is part of my data analytics portfolio demonstrating end-to-end skills:
SQL · Data Cleaning · Exploratory Analysis · Data Visualization · Business Communication

---

*⭐ If you found this project useful, consider giving it a star!*
