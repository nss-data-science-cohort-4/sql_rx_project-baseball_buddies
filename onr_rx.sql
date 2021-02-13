/*Which Tennessee counties had a disproportionately high number of opioid prescriptions?*/

-- total claim count per county
SELECT f.county, SUM(total_claim_count) AS total, population
FROM drug AS d
INNER JOIN prescription AS p1
USING(drug_name)
INNER JOIN prescriber AS p2
USING(npi)
INNER JOIN zip_fips AS z
ON p2.nppes_provider_zip5 = z.zip
INNER JOIN fips_county AS f
USING(fipscounty)
INNER JOIN population
USING (fipscounty)
WHERE f.state = 'TN' AND opioid_drug_flag = 'Y'
GROUP BY f.county, population;

-- opioid claim count per county
SELECT f.county, SUM(total_claim_count) AS total
FROM drug AS d
INNER JOIN prescription AS p1
USING(drug_name)
INNER JOIN prescriber AS p2
USING(npi)
INNER JOIN zip_fips AS z
ON p2.nppes_provider_zip5 = z.zip
INNER JOIN fips_county AS f
USING(fipscounty)
INNER JOIN population
USING (fipscounty)
WHERE f.state = 'TN' AND opioid_drug_flag = 'Y'
GROUP BY f.county
ORDER BY total DESC;

/* Who are the top opioid prescibers for the state of Tennessee? */
SELECT nppes_provider_last_org_name AS last_name, 
	nppes_provider_first_name AS first_name,
	total
FROM drug AS d
INNER JOIN prescriber AS p1
AS 
INNER JOIN zip_fips AS z
ON p1.nppes_provider_zip5 = z.zip
INNER JOIN population AS p2
USING(fipscounty)
INNER JOIN fips_county AS f

SELECT *
FROM overdose_deaths
ORDER BY fipscounty, year;

/* Q3 What did the trend in overdose deaths due to opioids look like in Tennessee from 2015 to 2018? */
SELECT year, SUM(overdose_deaths)
FROM overdose_deaths
GROUP BY year

SELECT *
FROM overdose_deaths
WHERE fipscounty LIKE '47%';
-- 380 rows

SELECT fipscounty
FROM fips_county
WHERE state = 'TN';
-- 96 rows

SELECT year, SUM(overdose_deaths), fipscounty
FROM overdose_deaths
GROUP BY year, fipscounty

-- ANS: 
SELECT *
FROM drug AS d
INNER JOIN prescription AS p2
USING (drug_name)
INNER JOIN prescriber AS p1
USING (npi)
INNER JOIN zip_fips AS z
ON p1.nppes_provider_zip5 = z.zip
INNER JOIN fips_county as f
USING (fipscounty)
INNER JOIN overdose_deaths as o
USING (fipscounty)
WHERE f.state = 'TN' AND opioid_drug_flag = 'Y' AND YEAR BETWEEN 2015 AND 2018
ORDER BY overdose_deaths DESC;

/*Q4 Is there an association between rates of opioid prescriptions and overdose deaths by county?*/
SELECT f.fipscounty, f.county , SUM(total_claim_count) as total, population
FROM drug AS d
INNER JOIN prescription AS p2
USING (drug_name)
INNER JOIN prescriber AS p1
USING (npi)
INNER JOIN zip_fips AS z
ON p1.nppes_provider_zip5 = z.zip
INNER JOIN fips_county as f
USING (fipscounty)
INNER JOIN population as p3
USING (fipscounty)
WHERE f.state = 'TN' AND opioid_drug_flag = 'Y'
GROUP BY f.fipscounty, f.county, population
ORDER BY total DESC;

SELECT SUM(overdose_deaths), fipscounty
FROM overdose_deaths
GROUP BY fipscounty

-- 2/11/2021 Updates
/* Q5: Is there any association between a particular type of opioid and number of overdose deaths?*/
WITH CTE AS (
	SELECT drug_name, generic_name, long_acting_opioid_drug_flag
	FROM drug
	WHERE opioid_drug_flag = 'Y'
)
SELECT DISTINCT(generic_name), overdose_deaths, generic_name, long_acting_opioid_drug_flag
FROM prescription AS p1
INNER JOIN CTE
USING (drug_name)
INNER JOIN prescriber AS p2
USING (npi)
INNER JOIN zip_fips AS z
ON p2.nppes_provider_zip5 = z.zip
INNER JOIN overdose_deaths AS o
USING (fipscounty)
WHERE z.fipscounty LIKE '47%'
GROUP BY overdose_deaths, generic_name, long_acting_opioid_drug_flag;

-- Isolating deaths per county in TN
WITH CTE AS (
	SELECT fipscounty, SUM(overdose_deaths)
	FROM overdose_deaths
	GROUP BY fipscounty
)
-- Bringing in other tables of interest
SELECT *
FROM zip_fips AS z
WHERE fipscounty LIKE '47%'
INNER JOIN CTE
USING (fipscounty)

-- find how many zip codes in TN split across multiple counties
SELECT zip, COUNT(zip)
FROM zip_fips
WHERE fipscounty LIKE '47%'
GROUP BY zip
ORDER BY count(zip) DESC;

-- find out whether/how zip codes are distributed across multiple counties
SELECT zip, fipscounty, MAX(tot_ratio)
FROM zip_fips
WHERE fipscounty LIKE '47%'
GROUP BY zip, fipscounty
ORDER BY zip;

-- Q: how do we select a singular zip code and county match based on highest max(tot_ratio) value?
SELECT zip, fipscounty, MAX(tot_ratio) AS highest_ratio
FROM zip_fips
WHERE fipscounty LIKE '47%'
GROUP BY zip, fipscounty
ORDER BY zip;

-- solution: window function!!!	
SELECT
	fipscounty, zip, MAX(tot_ratio) AS highest_ratio,
	RANK() OVER(
		PARTITION BY zip
		ORDER BY MAX(tot_ratio) DESC)
FROM zip_fips
WHERE fipscounty LIKE '47%' 
GROUP BY fipscounty, zip;

-- next step: if rank = 1 then fipscounty = our choice

-- selecting 95 counties of interest in TN and the different zip code(s) within them
WITH CTE AS (
	SELECT
	fipscounty, zip, MAX(tot_ratio) AS highest_ratio,
	RANK() OVER(
		PARTITION BY zip
		ORDER BY MAX(tot_ratio) DESC)
	FROM zip_fips
	WHERE fipscounty LIKE '47%' 
	GROUP BY fipscounty, zip
	ORDER BY zip
)
SELECT DISTINCT(fipscounty)
FROM CTE
WHERE rank = 1;

-- all counties in OD_Deaths have data for 4 years
SELECT DISTINCT(fipscounty), ARRAY_AGG(year), COUNT(year)
FROM overdose_deaths
GROUP BY fipscounty
ORDER BY COUNT(year);

-- all years in OD_Deaths have a value
SELECT overdose_deaths
FROM overdose_deaths
WHERE overdose_deaths IS NULL;

-- query exploring how many overdose deaths per county between 2015 and 2018?
-- PART A: this is our overdose deaths per county table
SELECT fipscounty, SUM(overdose_deaths) AS deaths_fipscounty, population
FROM overdose_deaths
INNER JOIN population
USING(fipscounty)
GROUP BY fipscounty, population;

-- exploring relationship between type of opioid and location
-- population
SELECT d.generic_name, d.drug_name, p1.total_day_supply
FROM drug AS d
INNER JOIN prescription AS p1
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
ORDER BY p1.total_day_supply DESC;

31932
31851

81
-- -------------------------------------------------------------------------------------------------
-- | fips1 | zip1 | sum_death_fips1 | generic_name_zip1 | total_day_supply_zip1 | population_fips1 |
-- | fips1 | zip2 | sum_death_fips1 | generic_name_zip2 | total_day_supply_zip2 | population_fips1 |
-- | fips1 | zip3 | sum_death_fips1 | generic_name_zip3 | total_day_supply_zip3 | population_fips1 |
-- -------------------------------------------------------------------------------------------------

WITH CTE AS (
	SELECT
	fipscounty, zip, tot_ratio AS highest_ratio,
	RANK() OVER(
		PARTITION BY zip
		ORDER BY tot_ratio DESC)
	FROM zip_fips
	WHERE fipscounty LIKE '47%'
	ORDER BY zip
),
CTE2 AS (SELECT fipscounty, zip
	FROM CTE
	WHERE rank = 1)
SELECT p.npi, CTE2.zip, CTE2.fipscounty, drug_name, generic_name, p.total_day_supply, p.total_claim_count
FROM drug AS d
INNER JOIN prescription as p
USING (drug_name)
INNER JOIN prescriber as p2
USING (npi)
INNER JOIN CTE2
On p2.nppes_provider_zip5 = CTE2.zip
WHERE opioid_drug_flag = 'Y'
ORDER BY p.total_day_supply desc;


