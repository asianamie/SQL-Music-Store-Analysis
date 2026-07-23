-- 📊 Technical Architecture & Production Queries

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

-- Finding the top 3 highest-paid job roles within each experience level (using a different dataset from above)

WITH RankedSalaries AS (
    SELECT 
        job_title,
        experience_level,
        salary_in_usd,
        -- DENSE_RANK assigns a rank partitioned (grouped) by experience_level
        DENSE_RANK() OVER (
            PARTITION BY experience_level 
            ORDER BY salary_in_usd DESC
        ) AS salary_rank
    FROM tech_salaries
)
SELECT 
    experience_level,
    job_title,
    salary_in_usd,
    salary_rank
FROM RankedSalaries
WHERE salary_rank <= 3;

-- Find job titles whose average salary is higher than the overall company-wide average salary
    
-- Step 1: Calculate the overall baseline salary across all roles
WITH GlobalAverage AS (
    SELECT AVG(salary_in_usd) AS overall_avg
    FROM tech_salaries
),

-- Step 2: Calculate the average salary per job title
RoleAverages AS (
    SELECT 
        job_title,
        AVG(salary_in_usd) AS role_avg
    FROM tech_salaries
    GROUP BY job_title
)

-- Step 3: Compare each role's average against the global baseline
SELECT 
    r.job_title,
    ROUND(r.role_avg, 2) AS role_avg_salary,
    ROUND(g.overall_avg, 2) AS global_avg_salary,
    ROUND(r.role_avg - g.overall_avg, 2) AS pay_difference
FROM RoleAverages r
CROSS JOIN GlobalAverage g
WHERE r.role_avg > g.overall_avg
ORDER BY pay_difference DESC;

-- Categorize pay into Low, Medium, and High bands, then count how many roles fall into each band (create conditional statements within query)

SELECT 
    experience_level,
    CASE 
        WHEN salary_in_usd < 80000 THEN 'Entry Pay (<$80k)'
        WHEN salary_in_usd BETWEEN 80000 AND 150000 THEN 'Mid Pay ($80k-$150k)'
        ELSE 'High Pay (>$150k)'
    END AS salary_tier,
    COUNT(*) AS total_positions
FROM tech_salaries
GROUP BY 
    experience_level, 
    salary_tier
ORDER BY 
    experience_level, 
    total_positions DESC;

-- Calculate the percentage pay increase from Mid-Level (MI) transitioning to Senior-Level (SE) across different job titles
-- Adding CASE WHEN with AVG function

WITH ExperienceComparison AS (
    SELECT 
        job_title,
        AVG(CASE WHEN experience_level = 'MI' THEN salary_in_usd END) AS mid_avg_salary,
        AVG(CASE WHEN experience_level = 'SE' THEN salary_in_usd END) AS senior_avg_salary
    FROM tech_salaries
    GROUP BY job_title
)
SELECT 
    job_title,
    ROUND(mid_avg_salary, 2) AS mid_salary,
    ROUND(senior_avg_salary, 2) AS senior_salary,
    -- Calculate percentage increase
    ROUND(((senior_avg_salary - mid_avg_salary) / mid_avg_salary) * 100, 2) AS pct_increase
FROM ExperienceComparison
WHERE mid_avg_salary IS NOT NULL AND senior_avg_salary IS NOT NULL
ORDER BY pct_increase DESC;
