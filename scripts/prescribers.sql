-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	x.npi,
	SUM(total_claim_count) AS claim_count,
	nppes_provider_last_org_name AS last_name
FROM prescription AS p
INNER JOIN prescriber AS x
USING (npi)
GROUP BY x.npi, last_name
ORDER BY claim_count DESC
LIMIT 1;

-- ANSWER: 1881634483	99707	"PENDLEY"
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	nppes_provider_first_name AS first_name,
	nppes_provider_last_org_name AS last_name,
	specialty_description,
	SUM(total_claim_count) AS claim_count
FROM prescription AS p
INNER JOIN prescriber AS x
USING (npi)
GROUP BY x.npi, last_name, first_name, specialty_description
ORDER BY claim_count DESC
LIMIT 1;

-- ANSWER: "BRUCE"	"PENDLEY"	"Family Practice"	99707

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
WITH x AS( --WITH CTE
SELECT
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
FULL JOIN prescriber
USING (npi)
GROUP BY specialty_description
ORDER BY specialty_description)
SELECT *
FROM x 
WHERE total_claims IS NULL;

SELECT --WITHOUT CTE AND HAVING
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
FULL JOIN prescriber
USING (npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL
ORDER BY specialty_description

--ANSWER: 15 specialty

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?


SELECT--still working through
	specialty_description, 
	SUM(total_claim_count) AS total_claims,
	COUNT(opioid_drug_flag = 'Y') AS opioid_count,
	COUNT(opioid_drug_flag = 'Y')/SUM(total_claim_count)*100 AS opioid_percentage
FROM prescriber
FULL JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
WHERE total_claim_count IS NOT NULL 
GROUP BY specialty_description
ORDER BY total_claims DESC;

SELECT --ignore
	opioid_drug_flag
FROM prescriber
FULL JOIN prescription
USING (npi)
LEFT JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
AND specialty_description = 'Family Practice'


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
	CAST(ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS money) AS per_day_cost
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
GROUP BY generic_name
ORDER BY per_day_cost DESC;

-- ANSWER: "C1 ESTERASE INHIBITOR"	"$3,495.22"

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

SELECT DISTINCT(cbsaname)
FROM cbsa AS c
WHERE cbsaname LIKE '%TN%';

--ANSWER: 10

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT --LARGEST 
	cbsaname AS cbsa_name,
	SUM(p.population) AS total_population
FROM cbsa AS c
INNER JOIN population AS p
USING (fipscounty)
GROUP BY c.cbsa, cbsaname
ORDER BY total_population DESC;

SELECT -- SMALLEST
	cbsaname AS cbsa_name,
	SUM(p.population) AS total_population
FROM cbsa AS c
INNER JOIN population AS p
USING (fipscounty)
GROUP BY c.cbsa, cbsaname
ORDER BY total_population;

WITH smallest AS ( 
	SELEC

--ANSWER 1: LARGEST - "Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410
--ANSWER 2: SMALLEST - "Morristown, TN"	116352

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT 
	c.cbsa, --indicates nulls where there is no cbsa
	fc.county AS county_name,
	pop.population AS total_population
FROM population AS pop
INNER JOIN fips_county AS fc
USING (fipscounty)
LEFT JOIN cbsa AS c
USING (fipscounty)
WHERE cbsaname IS NULL
ORDER BY total_population DESC;

--ANSWER: "SEVIER"	95,523

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT 
	drug_name,
	total_claim_count
FROM prescription 
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y'
		THEN 'Y' ELSE '' END AS opioid_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	p.drug_name,
	p.total_claim_count,
	CASE WHEN d.opioid_drug_flag = 'Y'
		THEN 'Y' ELSE '' END AS opioid_flag,
	p2.nppes_provider_first_name ||' '|| p2.nppes_provider_last_org_name AS prescriber_name
FROM drug AS d
INNER JOIN prescription AS p
USING (drug_name)
INNER JOIN prescriber AS p2
USING (npi)
WHERE p.total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT 
	p.npi,
	d.drug_name
FROM prescriber AS p
CROSS JOIN drug AS d
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT 
	p.npi,
	d.drug_name,
	SUM(p2.total_claim_count)
FROM prescriber AS p
CROSS JOIN drug AS d
FULL JOIN prescription AS p2
	USING (drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY d.drug_name, p.npi
ORDER BY SUM(p2.total_claim_count) DESC;

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT 
	p.npi,
	d.drug_name,
	COALESCE(SUM(p2.total_claim_count), '0')
FROM prescriber AS p
CROSS JOIN drug AS d
FULL JOIN prescription AS p2
	USING (drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY d.drug_name, p.npi
ORDER BY SUM(p2.total_claim_count) DESC;