SELECT *
FROM cbsa
LIMIT 10;

SELECT *
FROM drug
LIMIT 10;

SELECT *
FROM fips_county
LIMIT 10;

SELECT *
FROM overdose_deaths
LIMIT 10;

SELECT *
FROM population
LIMIT 10;

SELECT *
FROM prescriber
LIMIT 10;

SELECT drug_name, total_day_supply, total_30_day_fill_count
FROM prescription
WHERE drug_name = 'CEPHALEXIN'

SELECT *
FROM zip_flips
LIMIT 10;
-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	p1.npi, 
	p2.total_claim_count, 
	p1.nppes_provider_first_name AS first_name
FROM prescriber AS p1
INNER JOIN prescription AS p2 
USING (npi)
ORDER BY p2.total_claim_count DESC
LIMIT 10;

-- ANSWER: NPI: 1912011792, CLAIM COUNT: 4538
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	p1.nppes_provider_last_org_name AS last_org_name,
	p1.nppes_provider_first_name AS first_name,
	p1.specialty_description,
	p2.total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2 
USING (npi)
ORDER BY p2.total_claim_count DESC
LIMIT 1;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

WITH X AS ( 
SELECT
	p1.specialty_description AS specialty,
	SUM(p2.total_claim_count) AS total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2 
USING (npi)
GROUP BY p1.specialty_description)
SELECT * 
FROM X
ORDER BY total_claim_count DESC
LIMIT 1;

-- ANSWER: FAMILY PRACTICE 

--     b. Which specialty had the most total number of claims for opioids?

SELECT
	p1.specialty_description AS specialty,
	SUM(p2.total_claim_count) AS opioid_claim
FROM prescriber AS p1
INNER JOIN prescription AS p2 
USING (npi)
INNER JOIN drug AS d
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY p1.specialty_description
ORDER BY opioid_claim DESC
LIMIT 1;

--ANSWER: Nurse Practitioner

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT
	d.generic_name, 
	CAST(SUM(p.total_drug_cost) AS money) AS total_drug_cost
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
GROUP BY d.generic_name
ORDER BY total_drug_cost DESC;

--ANSWER: INSULIN GLARGINE,HUM.REC.ANLOG $104,264,066.35

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT 
	generic_name,
    CAST(ROUND(CASE 
		WHEN total_day_supply > 1 THEN (total_drug_cost / total_day_supply) 
		ELSE 0
    	END, 2) AS money) AS per_day_cost
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
ORDER BY per_day_cost DESC
LIMIT 10;

-- ANSWER: "IMMUN GLOB G(IGG)/GLY/IGA OV50"	$7,141.11

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT 
	drug_name,
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' 
		END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' 
		END AS drug_type,
	CAST(SUM(p.total_drug_cost) AS money) AS total_spent
FROM prescription AS p
LEFT JOIN drug AS d
USING (drug_name)
GROUP BY drug_type
ORDER BY drug_type DESC;

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

WITH x AS (
SELECT RIGHT(cbsaname, 2) AS name
FROM cbsa )
	SELECT COUNT(name) AS total_cbsas
	FROM x
	WHERE name = 'TN';

--ANSWER: 33

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT 
	cbsaname AS cbsa_name,
	SUM(p.population) AS total_population
FROM cbsa AS c
INNER JOIN population AS p
USING (fipscounty)
GROUP BY c.cbsa, cbsaname
ORDER BY total_population DESC;

--ANSWER 1: LARGEST - "Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410
--ANSWER 2: SMALLEST - "Morristown, TN"	116352

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.



-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.