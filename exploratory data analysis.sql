/*
  Layoff Analysis: A Story of a Declining Job Market

  Our journey begins by looking at the big picture.
  We want to understand the total number of layoffs per year to see
  if there's a trend or a significant event that stands out.
*/

-- Query 1: What does the overall trend look like?
-- We group the data by year to sum up all the layoffs.
-- This gives us an annual summary of the job market.
SELECT
  extract(year from dates),
  sum(total_laid_off)
FROM
  layoffdata_staging2
GROUP BY
  extract(year from dates)
ORDER BY
  extract(year from dates) ASC;

-- Query 2: Let's zoom in on the 'stage' of the company.
-- Are early-stage startups or more established companies being hit harder?
-- This query helps us understand where the impact is most significant.
SELECT
  stage,
  sum(total_laid_off)
FROM
  layoffdata_staging2
GROUP BY
  stage
ORDER BY
  sum desc;

-- Query 3: Now, let's look at the cumulative effect over time.
-- We want to see how the total number of layoffs grows with each passing month.
-- This creates a "rolling total" that visualizes the accumulation of layoffs,
-- a powerful way to see the escalating problem.
WITH rr AS (
  SELECT
    substring(dates::text from 1 for 7) AS dates,
    sum(total_laid_off) AS total_laid_off
  FROM
    layoffdata_staging2
  GROUP BY
    substring(dates::text from 1 for 7)
  ORDER BY
    substring(dates::text from 1 for 7) ASC
)
SELECT
  *,
  sum(total_laid_off) OVER (ORDER BY dates) AS rolling_total
FROM
  rr;

-- Query 4: Who are the biggest players in this story?
-- This query identifies the top 5 companies with the most layoffs each year.
-- We partition the data by year and rank the companies to find the ones
-- with the most significant impact on the total layoff numbers.
WITH tt(company, years, total_laid_off) AS (
  SELECT
    company,
    EXTRACT(year FROM dates) AS years,
    sum(total_laid_off)
  FROM
    layoffdata_staging2
  GROUP BY
    company,
    years
),
pp AS (
  SELECT
    company,
    years,
    total_laid_off,
    dense_rank() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranks
  FROM
    tt
  WHERE
    total_laid_off IS NOT null
)
SELECT
  *
FROM
  pp
WHERE
  ranks <= 5;


-- Query 5: How fast is this story unfolding?
-- We calculate the month-over-month percentage change in layoffs.
-- This helps us understand the pace of the downturn and see if the situation is
-- getting worse or if things are starting to stabilize.
WITH jj AS (
  SELECT
    substring(dates::text from 1 for 7) AS dated,
    sum(total_laid_off) AS total
  FROM
    layoffdata_staging2
  GROUP BY
    substring(dates::text from 1 for 7)
),
qq AS (
  SELECT
    *,
    sum(total) OVER (ORDER BY dated) AS cum
  FROM
    jj
)
SELECT
  *,
  abs(round(((lag(cum, 1) OVER ()) - cum) / (lag(cum, 1) OVER ()), 2)) AS pct_change
FROM
  qq
WHERE
  dated IS NOT null;
