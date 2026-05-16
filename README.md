# Tech Layoffs 2020–2026  
**End-to-End SQL Data Cleaning + Business Insights**

## Project Overview

- Took a raw, messy layoffs CSV file (~2,800 rows)
- Cleaned it completely using **pure SQL** (deduplication, date parsing, NULL handling, type conversion)
- Performed EDA to extract meaningful business metrics and trends
- Goal: Turn unusable data into reliable insights about tech layoffs

**Dataset source**: Public layoffs data (inspired by layoffs.fyi / Kaggle-style)

**Time period covered**: 2020–2026

## Tech Stack & Skills Demonstrated

- MySQL 8.0+
- Window functions (ROW_NUMBER + PARTITION BY for deduplication)
- REGEXP + CASE (robust handling of mixed date formats)
- NULLIF (correct missing value handling)
- Self-join (imputing missing industry values)
- Aggregate queries (SUM, AVG, GROUP BY for KPIs)
- Before/after diagnostics (proof of cleaning quality)

## Cleaning Process – Step by Step

1. **Created safe staging table** (never clean raw data)  
2. **Removed exact duplicates** using ROW_NUMBER → reduced from ~2,797 to ~2,750 rows  
3. **Standardized text** (TRIM + fixed typos like 'Deep Instict' → 'Deep Instinct')  
4. **Fixed messy dates** (slashes/dashes/mixed order) → all now proper DATE type  
5. **Converted blanks → NULL** (correct for aggregates like COUNT/AVG/SUM)  
6. **Changed numeric columns** to DECIMAL (type safety for money & %)  
7. **Filled missing industry** via self-join on same company  
8. **Removed useless rows** (no real layoff info)  
9. **Validated** (before/after counts, date range, top companies)


## Key Business Metrics – After Cleaning

| Metric                              | Value              | Business Insight                                      |
|-------------------------------------|--------------------|-------------------------------------------------------|
| Total employees laid off            | ~250,000           | Massive scale of tech job losses                      |
| Average layoff percentage           | ~18.4%             | Companies typically cut 1 in 5 employees per round    |
| Total layoff events                 | ~2,750             | Widespread restructuring across the industry          |
| Time period                         | 2020-03-13 to 2026-02-26 | Captures post-COVID boom & correction wave            |
| Top industry                        | Software           | Software sector suffered largest absolute losses     |
| Top company                         | Meta               | Meta alone laid off tens of thousands                 |
| Companies with 2+ layoff rounds     | ~120               | Ongoing cost pressure in several organizations        |
| Share in United States              | ~78%               | US tech ecosystem dominated global layoffs            |


## EDA Highlights & Business Takeaways

### Top 10 Companies by Total Layoffs
- Meta, Amazon, Google, etc. dominate absolute numbers  
  → Large tech firms drove most job losses due to scale

### Most Affected Industries
- Software, Consumer, Retail at the top  
  → Over-hiring during 2020–2022 boom followed by demand drop

### Layoff Trends Over Time
- Peak in 2023 — highest volume of events and people affected  
  → Post-pandemic correction wave was strongest that year

### Companies with Multiple Rounds
- ~120 companies announced 2+ layoffs  
  → Indicates chronic restructuring, not one-time adjustments

### Final Data Quality
- Missing values reduced to near zero after cleaning  
  → Dataset is now reliable for reporting & visualization

## What I Learned

- Real-world data is always messy — dates & blanks cause most issues
- Cleaning is not just technical — it needs business logic (e.g. 0% → NULL when meaningless)
