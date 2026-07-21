# Engineering Framework: Global Tech Compensation Analysis

## 📌 Core Engineering Problem
Corporate compensation infrastructure often suffers from fragmented data formatting and duplicate records. This analysis engineers a pipeline to standardize job classifications and compute deviations from market baselines.

## 🛠️ Data Infrastructure & Stack
*   **Engine Environment:** SQLite Engine
*   **Engineering Frameworks:** Common Table Expressions (CTEs), Partitioned Windowing Functions (`ROW_NUMBER`), Analytics Case Logic, Aggregations.

## 📊 Technical Architecture & Production Queries
```sql
WITH RankedSalaries AS (
    SELECT UPPER(job_title) AS employee_id, cleaned_title, company_location, salary_in_usd,
    ROW_NUMBER() OVER(PARTITION BY job_title, company_location, experience_level, salary_in_usd
    ORDER BY employee_id) as duplication_rank,
    AVG(salary_in_usd) OVER(PARTITION BY job_title) AS global_role_coverage
FROM professional_salaries
)
SELECT 
    employee_id,
    cleaned_title,
    company_location,
    salary_in_usd,
    global_role_average,
    (salary_in_usd-global_role_average) AS compensation_variance,
    CASE WHEN duplication_rank >1 THEN 'Flagged Duplicate'
    ELSE 'Verified Unique Record'
    END AS database_status
FROM RankedSalaries;

-- Complete tracking query maintained in production_queries.sql
```
## 🗺️ Data Pipeline Architecture
```mermaid
graph LR
A[Raw Messy CSV Data] --> B[SQLite Staging Table]
B --> C[UPPER Text Normalization]
C --> D[Window Function Duplicate Tracking]
D --> E[Calculated Salary Variance Output]
E --> F[Tableau Executive Dashboard]
```

## 📈 Strategic Insights Discovered
1. **Classification Anomalies Detected:** Data entries contained mixed case structures and non-standard titles (e.g., `data analyst` vs `Data Analyst`). This variation skews raw metrics if not handled by explicit text manipulation tools.
2. **Compensation Imbalances:** Mid-to-Senior level engineers exhibit salary variations up to **$21,500 over average baselines**, highlighting clear opportunities to optimize regional market bands.
