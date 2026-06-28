SELECT * 
FROM public."Med_care_data";

--- GENERAL OVERVIEW
-- Total Patients
SELECT
	COUNT(patient_id) AS total_patient
FROM public."Med_care_data";

-- Average Wait time
SELECT 
	ROUND(
		AVG(wait_time_minutes),2) AS Avg_wait_time
FROM public."Med_care_data";

-- Avg length of stay
SELECT
	ROUND(
		AVG(length_of_stay),2) AS avg_length_of_stay
FROM public."Med_care_data";

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

-- Total Revenue 
SELECT 
	SUM(treatment_cost) AS total_revenue
FROM public."Med_care_data";

-- Total Cost
SELECT
	SUM(out_of_pocket_cost) AS total_cost
FROM public."Med_care_data";


-- OPERATIONS
--Department with the longest wait times
SELECT 
	department,
	ROUND(
		AVG(wait_time_minutes),2) AS Avg_wait_time
FROM public."Med_care_data"								-- Cardiology has the longest wait times
GROUP BY department
ORDER BY Avg_wait_time DESC;

-- Hospital Branch with the highest patient volume
SELECT
	hospital_branch,
	COUNT(patient_id) AS total_patient
FROM public."Med_care_data"     			-- North wing has the highest patient volume
GROUP BY hospital_branch
ORDER BY total_patient DESC;

-- Branch with the highest bed occupancy rate
WITH occupancy AS(
	SELECT
		COUNT(bed_assigned) AS bed_occupancy
	FROM public."Med_care_data" 
)
SELECT
	b.hospital_branch,
	ROUND(
	COUNT(o.bed_occupancy) * 100.0 / bed_occupancy ,2) AS occupancy_rate
FROM public."Med_care_data" b
CROSS JOIN occupancy o
WHERE bed_assigned = 'Yes'
GROUP BY b.hospital_branch, o.bed_occupancy
ORDER BY occupancy_rate DESC;

-- Department with the longest avg length of stay
SELECT
	department,
	ROUND(											-- Orthopedics
		AVG(length_of_stay),2) AS Avg_length_of_stay
FROM public."Med_care_data"
GROUP BY department
ORDER BY Avg_length_of_stay DESC;

-- Doctor that handles the most patient
SELECT
	doctor_assigned,
	COUNT(patient_id) AS total_patient					--Dr Smith
FROM public."Med_care_data"
GROUP BY doctor_assigned
ORDER BY total_patient DESC;

--- PATIENT SATIFACTION & EXPERIENCE

-- Relationship between wait time and patient satisfaction
SELECT
	patient_satisfaction_score,
	wait_time_minutes                -- Satisfaction drops when it exceed 60 min
FROM public."Med_care_data"			-- although there are still some high satisfaction
WHERE wait_time_minutes >= 60        -- Satisfaction deoes not solely depend on wait time
GROUP BY patient_satisfaction_score, wait_time_minutes
ORDER BY wait_time_minutes ASC;

-- Department with the lowest satisfaction score
SELECT
	department,
	COUNT(patient_satisfaction_score) count_low_satisfa_scores
FROM public."Med_care_data"
WHERE patient_satisfaction_score < 5
GROUP BY department
ORDER BY count_low_satisfa_scores DESC;

-- Doctors with the most satisfied patient
SELECT
	doctor_assigned,
	COUNT(patient_satisfaction_score) AS count_high_satisfaction
FROM public."Med_care_data"										-- Dr Smith
WHERE patient_satisfaction_score >= 7
GROUP BY doctor_assigned
ORDER BY count_high_satisfaction DESC;

-- How treatment outcome affects satisfaction
SELECT
	treatment_outcome,
	COUNT(patient_satisfaction_score) AS high_satisfation 
FROM public."Med_care_data"	             -- There is a very close margin, there is no direct
WHERE patient_satisfaction_score > 7     -- relstionship between both
GROUP BY treatment_outcome
ORDER BY high_satisfation  DESC


--- FINANCIAL & REVENUE ANALYSIS

-- Department with the highest treatment cost
SELECT
	department,
	SUM(treatment_cost) AS total_treatment_cost
FROM public."Med_care_data"	    					-- General Department incurred the highest 
GROUP BY department									-- treatment cost
ORDER BY total_treatment_cost DESC;

-- Insurance type that covers the most expenses
SELECT
	insurance_type,
	SUM(insurance_coverage) AS insurance_coverage_
FROM public."Med_care_data"						 -- Private Insurance covered the most 
GROUP BY insurance_type     					 -- treatment cost
ORDER BY insurance_coverage_ DESC;

-- Diagnosis that are most expensive to treat
SELECT
	diagnosis,
	ROUND(
		AVG(treatment_cost),2) AS treatment_cost_
FROM public."Med_care_data"							-- Arthritis is the most expensive to treat
GROUP BY diagnosis
ORDER BY treatment_cost_ DESC;

-- Are Expensive treatment effective (above 5000)
WITH t_treatment_cost AS(
	SELECT
		SUM(treatment_cost) AS treatment_cost_
	FROM public."Med_care_data"
	WHERE treatment_cost > 5000
)
SELECT
	m.treatment_outcome,
	ROUND(
		SUM(m.treatment_cost) * 100.0/ t.treatment_cost_,2) AS perc_outcome
FROM public."Med_care_data"	m
CROSS JOIN t_treatment_cost t
WHERE m.treatment_cost > 5000
GROUP BY m.treatment_outcome, t.treatment_cost_
ORDER BY perc_outcome DESC;

-- Insurance VS patients cost absorption
WITH cost_aggregation AS (
	SELECT
		SUM(treatment_cost) AS total_treatment_cost,
		SUM(Insurance_coverage) AS insurance_coverage_,
		SUM(out_of_pocket_cost) AS patient_coverage
	FROM public."Med_care_data"
),
perc_calc AS(
	SELECT
		ROUND(
			(insurance_coverage_ * 100.0) / (total_treatment_cost)
			,2) AS insurance_coverage_perc,
		ROUND(
			(patient_coverage * 100.0) / (total_treatment_cost)
			,2) AS patient_coverage_perc
	FROM cost_aggregation
)
SELECT
	insurance_coverage_perc,
	patient_coverage_perc
FROM perc_calc 
GROUP BY insurance_coverage_perc, patient_coverage_perc;

--- TREATMENT/ READMISSION ANALYSIS
-- Diagnosis with the highest readmission rate
WITH total_readmissiom AS(
	SELECT
		COUNT(readmitted_within_30_days) AS t_readmission
	FROM public."Med_care_data"
	WHERE readmitted_within_30_days = 'Yes'
),
readmission_rate_calc AS (
	SELECT
		r.diagnosis,
		ROUND(
			COUNT(readmitted_within_30_days) * 100.0 / t.t_readmission
			,2) AS readmission_rate
	FROM public."Med_care_data" r
	CROSS JOIN total_readmissiom t
	WHERE readmitted_within_30_days = 'Yes'
	GROUP BY r.diagnosis, t.t_readmission
)
SELECT
	diagnosis,
	readmission_rate
FROM readmission_rate_calc
GROUP BY diagnosis,readmission_rate
ORDER BY readmission_rate DESC;

-- department with the highest readmission
WITH total_readmissiom AS(
	SELECT
		COUNT(readmitted_within_30_days) AS t_readmission
	FROM public."Med_care_data"
	WHERE readmitted_within_30_days = 'Yes'
),
readmission_rate_calc AS (
	SELECT
		r.department,
		ROUND(
			COUNT(readmitted_within_30_days) * 100.0 / t.t_readmission
			,2) AS readmission_rate
	FROM public."Med_care_data" r
	CROSS JOIN total_readmissiom t
	WHERE readmitted_within_30_days = 'Yes'
	GROUP BY r.department, t.t_readmission
)
SELECT
	department,
	readmission_rate
FROM readmission_rate_calc
GROUP BY department,readmission_rate
ORDER BY readmission_rate DESC;

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

-- Departments and their recovery rate
WITH recovery_calc AS(
	SELECT
		COUNT(treatment_outcome) AS treatment_outcome_
	FROM public."Med_care_data"
	WHERE treatment_outcome = 'Recovered'
)
SELECT
	d.department,
	ROUND(
		COUNT(d.treatment_outcome) * 100.0 / r.treatment_outcome_
	,2) AS recovery_rate
FROM public."Med_care_data" d
CROSS JOIN recovery_calc r
WHERE treatment_outcome = 'Recovered'
GROUP BY d.department, r.treatment_outcome_
ORDER BY recovery_rate DESC; 

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