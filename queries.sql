## 📊 Technical Architecture & Production Queries
```sql
WITH RankedSalaries AS (
    SELECT UPPER(job_title) AS cleaned_title, employee_id, company_location, salary_in_usd,
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
    global_role_coverage,
    (salary_in_usd-global_role_coverage) AS compensation_variance,
    CASE WHEN duplication_rank >1 THEN 'Flagged Duplicate'
    ELSE 'Verified Unique Record'
    END AS database_status
FROM RankedSalaries;

-- Complete tracking query maintained in production_queries.sql
```
## 🗺️ Data Pipeline Architecture

```mermaid
graph TD
A[Raw Messy CSV Data] --> B[SQLite Staging Table]
B --> C[UPPER Text Normalization]
C --> D[Window Function Duplicate Tracking]
D --> E[Calculated Salary Variance Output]
E --> F[Tableau Executive Dashboard]
```
