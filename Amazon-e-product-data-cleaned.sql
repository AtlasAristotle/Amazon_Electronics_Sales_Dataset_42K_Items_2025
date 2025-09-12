--The columns has_coupon and  is_sponsored were dropped prior to being uploaded to sql
--In order to analyze data properply we need to adequately clean the data.
-- Preview first 100 rows of the dataset
SELECT * 
FROM public.amazon_e1_products AS datar
LIMIT 100;
--Because I know that there are no nulls in the product title column, I can move to the ratings column to start my cleaning.
-- Check for missing ratings
SELECT rating
FROM public.amazon_e1_products 
WHERE rating IS NULL;

-- Convert rating text (e.g., '4.6 out of 5 stars') to numeric by taking the first 3 characters
UPDATE public.amazon_e1_products
SET rating = CAST(LEFT(rating, 3) AS numeric)
WHERE rating IS NOT NULL;

-- Enforce numeric data type on rating column ( This step could have been done by ignoreing the above code and optimzing for the below)
ALTER TABLE public.amazon_e1_products
ALTER COLUMN rating TYPE numeric 
USING CAST(LEFT(rating, 3) AS numeric);

-- Identify rows where `bought_in_last_month` does not match expected format ( some rows have List 'Price:' or 'Typical:' )
SELECT bought_in_last_month
FROM public.amazon_e1_products
WHERE bought_in_last_month NOT LIKE '%bought in past month%';

-- Clean invalid entries by setting them to NULL
UPDATE public.amazon_e1_products
SET bought_in_last_month = NULL
WHERE bought_in_last_month NOT LIKE '%bought in past month%';

-- Extract portion before '+' (e.g., '200+' → '200')
SELECT LEFT(bought_in_last_month, POSITION('+' IN bought_in_last_month))
FROM public.amazon_e1_products;

-- Update column with extracted numeric portion
UPDATE public.amazon_e1_products
SET bought_in_last_month = LEFT(bought_in_last_month, POSITION('+' IN bought_in_last_month))
WHERE bought_in_last_month LIKE '%bought in past month%';

-- Inspect current/discounted price values (I am going down every column to do my checks)
SELECT "current/discounted_price"
FROM public.amazon_e1_products
LIMIT 1000;

-- Round up discounted prices to nearest integer (THis is optional)
UPDATE public.amazon_e1_products
SET "current/discounted_price" = CEILING("current/discounted_price");

-- Extract numeric portion of price_on_variant (remove '$') ( Before updating the data it is always a good idea to check and make sure everything looks correct - that is what the select is doing)
SELECT RIGHT(price_on_variant, LENGTH(price_on_variant) - POSITION('$' IN price_on_variant) + 1)
FROM public.amazon_e1_products
WHERE POSITION('$' IN price_on_variant) > 0;

-- Update column by stripping '$'
UPDATE public.amazon_e1_products
SET price_on_variant = RIGHT(price_on_variant, LENGTH(price_on_variant) - POSITION('$' IN price_on_variant) + 1)
WHERE POSITION('$' IN price_on_variant) > 0;

-- Set to NULL where no '$' present
UPDATE public.amazon_e1_products
SET price_on_variant = NULL
WHERE POSITION('$' IN price_on_variant) < 1;

-- Fix missing listed_price by replacing with current/discounted_price
SELECT "current/discounted_price", listed_price
FROM public.amazon_e1_products
WHERE POSITION('$' IN listed_price) < 1;

UPDATE public.amazon_e1_products
SET listed_price = "current/discounted_price"
WHERE POSITION('$' IN listed_price) < 1;

-- Remove first character from price_on_variant (alternative cleaning)
SELECT RIGHT(price_on_variant, LENGTH(price_on_variant) - 1)
FROM public.amazon_e1_products
WHERE POSITION('$' IN price_on_variant) > 0;

UPDATE public.amazon_e1_products
SET price_on_variant = RIGHT(price_on_variant, LENGTH(price_on_variant) - 1)
WHERE POSITION('$' IN price_on_variant) > 0;

-- Remove decimals by concatenating integer and fractional parts
UPDATE public.amazon_e1_products 
SET price_on_variant = LEFT(price_on_variant, POSITION('.' IN price_on_variant) - 1)
                       || RIGHT(price_on_variant, POSITION('.' IN price_on_variant))
WHERE price_on_variant IS NOT NULL;

-- Keep only digits in price_on_variant (remove non-numeric)
SELECT regexp_replace(price_on_variant, '\\D', '', 'g')
FROM public.amazon_e1_products
WHERE price_on_variant LIKE '%d%';

UPDATE public.amazon_e1_products
SET price_on_variant = regexp_replace(price_on_variant, '\\D', '', 'g')
WHERE price_on_variant LIKE '%d%';

-- Convert cleaned price_on_variant to numeric
ALTER TABLE public.amazon_e1_products 
ALTER COLUMN price_on_variant TYPE numeric 
USING REPLACE(REPLACE(REPLACE(price_on_variant, ',', ''), '$', ''), ' ', '')::numeric;

-- Clean listed_price by removing non-digit characters
SELECT regexp_replace(listed_price, '\\D', '', 'g')
FROM public.amazon_e1_products
WHERE POSITION('$' IN listed_price) > 0;

UPDATE public.amazon_e1_products
SET listed_price = regexp_replace(listed_price, '\\D', '', 'g')
WHERE POSITION('$' IN listed_price) > 0;

-- Convert listed_price to numeric
ALTER TABLE public.amazon_e1_products
ALTER COLUMN listed_price TYPE numeric USING listed_price::numeric;

-- Drop unnecessary columns ( I will not be needing these for my data analysis)
ALTER TABLE amazon_e1_products
DROP buy_box_availability,
DROP delivery_details,
DROP sustainability_badges;

-- Create a temporary cleaned dataset for further analysis
CREATE TEMP TABLE cleaned_data AS
SELECT *
FROM public.amazon_e1_products;

-- Preview cleaned data
SELECT *
FROM cleaned_data;



