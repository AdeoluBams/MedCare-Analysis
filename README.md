# MedCare-Analysis

## Table of Contents

- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)
- [Data Cleaning](#data-cleaning)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Analysis Query Highlight](#data-analysis-query-highlight)
- [Findings](#findings)
- [References](#references)


## Project Overview
This is an end-to-end Analysis into the performannce and growth of MedCare healthcare business.

## Data Sources
Med_care data: The primary dataset used for this analysis is the "Med_care data.csv" file, containing detailed information about the sales made by the company. 

## Tools
- Excel - Data Cleaning 
   - [Download Here](https://microsoft.com)
- PostgreSQl - Data Analysis
   - [Download Here](https://www.postgresql.org/download/)
- PowerBI - Creating Report
   - [Download Here](https://www.microsoft.com/en-us/download/details.aspx?id=58494&msockid=2fafce07f9f165923597d8d4f8e36471)

## Data Cleaning
- Data loading and Inspection
- Gender, Insurabce type and department, columns standardisation
- Handling Null values
-  Date Format transfromation ("yyy-MM-dd)
-  Handling null values in comorbidities
-  Columns Formatting
-  Data Grain_level Identification 

## Exploratory Data Analysis
- What is the readmission rate?
- How does severity level influence recovery?
- What department get the most readmission?
- Which doctor recorded the highest recovery rate?

## Data Analysis Query Highlight
```sql
-- Readmission Rate
WITH t_readmission AS(
	SELECT
		COUNT(readmitted_within_30_days) AS readmission
	FROM public."Med_care_data"
	WHERE readmitted_within_30_days = 'Yes'
)
SELECT
	ROUND(
		(t.readmission * 100) / COUNT(r.readmitted_within_30_days)
		,2) AS readmission_rate
FROM public."Med_care_data" r
CROSS JOIN t_readmission t
GROUP BY t.readmission; 

```
```sql
-- Recovery rate
WITH recovery_calc AS(
	SELECT
		COUNT(treatment_outcome) AS treatment_outcome_
	FROM public."Med_care_data"
)
SELECT
	ROUND(
		COUNT(d.treatment_outcome) * 100.0 / r.treatment_outcome_
	,2) AS recovery_rate
FROM public."Med_care_data" d
CROSS JOIN recovery_calc r
WHERE treatment_outcome = 'Recovered'
GROUP BY r.treatment_outcome_
ORDER BY recovery_rate DESC; 
```
```sql
-- Severity level against recovery probability
WITH recovery_calc AS(
	SELECT
		COUNT(treatment_outcome) AS treatment_outcome_
	FROM public."Med_care_data"
	WHERE treatment_outcome = 'Recovered'
)
SELECT
	d.severity_level,
	ROUND(
		COUNT(d.treatment_outcome) * 1.0 / r.treatment_outcome_
	,2) AS recovery_rate
FROM public."Med_care_data" d
CROSS JOIN recovery_calc r
WHERE treatment_outcome = 'Recovered'
GROUP BY d.severity_level, r.treatment_outcome_
ORDER BY recovery_rate DESC; 
```
```sql
-- are patient with commorbidities more likely to return
WITH total_readmissiom AS(
	SELECT
		COUNT(readmitted_within_30_days) AS t_readmission
	FROM public."Med_care_data"
	WHERE readmitted_within_30_days = 'Yes'
),
readmission_rate_calc AS (
	SELECT
		r.comorbidities,
		ROUND(
			COUNT(readmitted_within_30_days) * 1.0 / t.t_readmission
			,2) AS readmission_rate
	FROM public."Med_care_data" r
	CROSS JOIN total_readmissiom t
	WHERE readmitted_within_30_days = 'Yes' AND comorbidities = 'Yes'
	GROUP BY r.comorbidities, t.t_readmission
)
SELECT
	comorbidities,
	readmission_rate
FROM readmission_rate_calc
GROUP BY comorbidities,readmission_rate
ORDER BY readmission_rate DESC;

```

## Findings
- [Access the full Report Here]



## References
[Stack Overflow](https://stackoverflow.com/)

No file chosen
Attach files by dragging & dropping, selecting or pasting them.
