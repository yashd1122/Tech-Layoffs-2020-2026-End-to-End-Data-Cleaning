
-- ====================================================================
-- Data Cleaning & EDA Project – Global Tech Layoffs Dataset 2020-2026
-- ====================================================================

SELECT * 
FROM layoffs;

-- 1. Create a safe staging table 

CREATE TABLE layoffs_staging2 LIKE layoffs;

SELECT * 
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT * FROM layoffs;


-- Dataset Size Comparison: Before Deduplication

SELECT 
    'Before dedup' AS step,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT company) AS unique_companies
FROM layoffs_staging2;

-- 2. Remove exact duplicates using row_number

-- Add row number to identify duplicates

WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
               ORDER BY company
           ) AS row_num
    FROM layoffs_staging2
)
SELECT * FROM duplicates WHERE row_num > 1;   -- see duplicates first

-- YES THERE ARE SOME DUPLICATES SO WE CREATE NEW TABLE WITH CLEAN DATA AS layoff_clean

CREATE TABLE layoffs_clean AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
               ORDER BY company  
           ) AS rown
    FROM layoffs_staging2
) ranked
WHERE rown = 1;

SELECT * FROM layoffs_clean ; 


-- 3. Standardize / trim strings

UPDATE layoffs_clean
SET 
    company   = TRIM(company),
    location  = TRIM(location),
    industry  = TRIM(industry),
    country   = TRIM(country),
    stage     = TRIM(stage);
    
-- Fix common inconsistencies

SELECT distinct country
FROM layoffs_clean;

UPDATE layoffs_clean
SET company = 'Deep Instinct'
WHERE company  IN ('Deep Instict');

UPDATE layoffs_clean
SET company = 'Juniper Networks'
WHERE company  IN ('Juni Networks');

-- Fix common inconsistencies

UPDATE layoffs_clean
SET industry = 'Data'
WHERE industry IN ('data', 'Data.');

-- Fix Date Format 

SELECT `date`
FROM layoffs_clean;

UPDATE layoffs_clean
SET `date` = CASE 
    WHEN `date` REGEXP '^[0-1]?[0-9]/[0-3]?[0-9]/[12][0-9]{3}$' 
         THEN STR_TO_DATE(`date`, '%m/%d/%Y')          -- 4/8/2022 or 11/17/2022
    
    WHEN `date` REGEXP '^[0-1]?[0-9]-[0-3]?[0-9]-[12][0-9]{3}$' 
         THEN STR_TO_DATE(`date`, '%m-%d-%Y')          -- 04-08-2022 or 11-17-2022
    
    WHEN `date` REGEXP '^[0-3]?[0-9]-[0-1]?[0-9]-[12][0-9]{3}$' 
         THEN STR_TO_DATE(`date`, '%d-%m-%Y')          -- 08-04-2022 or 17-11-2022
    
    WHEN `date` REGEXP '^[12][0-9]{3}-[0-1][0-9]-[0-3][0-9]$' 
         THEN STR_TO_DATE(`date`, '%Y-%m-%d')          -- 2022-04-08
    
    ELSE NULL
END;

-- Convert date data type

ALTER TABLE layoffs_clean
MODIFY COLUMN `date`DATE;

-- Convert numeric columns data type
ALTER TABLE layoffs_clean
    MODIFY total_laid_off       DECIMAL(10,1),
    MODIFY percentage_laid_off  DECIMAL(5,4),
    MODIFY funds_raised         DECIMAL(15,2);

-- 4. Convert empty strings → NULL

SELECT 
    'Before NULLIF' AS step,
    COUNT(*) total,
    SUM(total_laid_off = '' OR total_laid_off IS NULL) missing_total,
    SUM(percentage_laid_off = '' OR percentage_laid_off IS NULL) missing_pct
FROM layoffs_clean;

UPDATE layoffs_clean
SET 
    total_laid_off       = NULLIF(TRIM(total_laid_off), ''),
    percentage_laid_off  = NULLIF(TRIM(percentage_laid_off), ''),
    funds_raised         = NULLIF(TRIM(funds_raised), ''),
    industry             = NULLIF(TRIM(industry), ''),
    stage                = NULLIF(TRIM(stage), ''),
    location             = NULLIF(TRIM(location), ''),
    country              = NULLIF(TRIM(country), '');

-- After NULLIF conversion

SELECT 
    'After NULLIF' AS step,
    COUNT(*) total,
    SUM(total_laid_off IS NULL) missing_total,
    SUM(percentage_laid_off IS NULL) missing_pct,
    SUM(industry IS NULL) missing_industry
FROM layoffs_clean;

UPDATE layoffs_clean
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 0
  AND (total_laid_off IS NULL OR total_laid_off <= 10);


-- 5. Optional: Fill some missing industry values 

UPDATE layoffs_clean t1
INNER JOIN layoffs_clean t2
    ON t1.company = t2.company
    AND t1.industry IS NULL
    AND t2.industry IS NOT NULL
SET t1.industry = t2.industry;

-- 6. Remove useless rows (no real layoff numbers)
DELETE FROM layoffs_clean
WHERE (total_laid_off IS NULL OR total_laid_off = 0)
  AND (percentage_laid_off IS NULL OR percentage_laid_off = 0);

-- 7 Now Drop Extra Column

ALTER TABLE layoffs_clean
DROP COLUMN rown;

-- Dataset Size Comparison: After Deduplication

SELECT 
    'AFTER dedup' AS step,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT company) AS unique_companies
FROM layoffs_clean;

-- Final validation

-- Final Table Structure After Cleaning

DESCRIBE layoffs_clean;

-- Date Range and Total Row Count – Final Check

SELECT MIN(`date`), MAX(`date`), COUNT(*) FROM layoffs_clean;

-- Companies with the Highest Number of Layoffs

SELECT company, SUM(total_laid_off) laid_off
FROM layoffs_clean
GROUP BY company
ORDER BY laid_off DESC;

-- The table layoffs_clean is now your cleaned version.

-- ===========================================================
-- EDA - Exploratory Data Analysis on Cleaned Layoffs Data
-- ===========================================================

-- 1. Basic Overview - Summary Statistics

SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT company) AS unique_companies,
    MIN(`date`) AS earliest_layoff,
    MAX(`date`) AS latest_layoff,
    SUM(total_laid_off) AS total_people_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_percentage_laid_off
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL;

-- 2. Layoffs by Year & Month (trend over time)

SELECT 
    YEAR(`date`) AS layoff_year,
    MONTH(`date`) AS layoff_month,
    COUNT(*) AS number_of_layoff_events,
    SUM(total_laid_off) AS total_people_laid_off
FROM layoffs_clean
WHERE `date` IS NOT NULL
GROUP BY layoff_year, layoff_month
ORDER BY layoff_year DESC, layoff_month DESC;

-- 3. Top 10 Companies by Total Employees Laid Off

SELECT 
    company,
    SUM(total_laid_off) AS total_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_percentage,
    COUNT(*) AS number_of_layoff_rounds
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY total_laid_off DESC
LIMIT 10;

-- 4. Top 10 Industries by Total Layoffs

SELECT 
    industry,
    COUNT(*) AS number_of_events,
    SUM(total_laid_off) AS total_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_percentage
FROM layoffs_clean
WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY total_laid_off DESC
LIMIT 10;

-- 5. Layoffs by Country

SELECT 
    country,
    COUNT(*) AS number_of_events,
    SUM(total_laid_off) AS total_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_percentage
FROM layoffs_clean
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_laid_off DESC
LIMIT 15;

-- 6. Layoffs by Company Stage (Post-IPO, Series B, etc.)

SELECT 
    stage,
    COUNT(*) AS number_of_events,
    SUM(total_laid_off) AS total_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_percentage
FROM layoffs_clean
WHERE stage IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY total_laid_off DESC;

-- 7. Companies with Multiple Layoff Rounds

SELECT 
    company,
    COUNT(*) AS layoff_rounds,
    SUM(total_laid_off) AS total_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_percentage
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
GROUP BY company
HAVING layoff_rounds > 1
ORDER BY layoff_rounds DESC, total_laid_off DESC
LIMIT 10;

-- 8. Largest single layoff events

SELECT 
    company,
    total_laid_off,
    percentage_laid_off,
    `date`,
    industry,
    country
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC
LIMIT 10;

-- 9. Missing data summary (quality check)

SELECT 
    SUM(total_laid_off IS NULL) AS missing_total_laid_off,
    SUM(percentage_laid_off IS NULL) AS missing_percentage,
    SUM(industry IS NULL) AS missing_industry,
    SUM(`date` IS NULL) AS missing_date,
    SUM(funds_raised IS NULL) AS missing_funds
FROM layoffs_clean;
