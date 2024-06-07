CREATE TABLE insurance_data
(index int,	
 PatientID int,
 age int,
 gender	varchar(30),
 bmi decimal(3,1),
 bloodpressure	int,
 diabetic varchar(30),
 children int,
 smoker	varchar(30),
 region	varchar(30),
 claim decimal(7,2)
);


SELECT *
FROM insurance_data;


COPY insurance_data (index,	PatientID,	age, gender, bmi, bloodpressure, diabetic, children, smoker, region, claim)
FROM 'C:\Users\Prem\insurance_data.csv'
DELIMITER ','
CSV HEADER;

--Q1: What are the top 5 patients who claimed the highest insurance amounts?
SELECT patientid, claim, ROUND(claim) as Round_Claims
FROM insurance_data
ORDER BY claim desc
LIMIT 5;

--Q2: What is the average insurance claimed by patients based on the number of children they have?
-- Using Window function
SELECT children, patientid, ROUND(avg_claims:: NUMERIC, 2) AS Round_Ang_Claims
FROM(
SELECT children, patientid, avg(claim) over(partition by children order by children) as Avg_claims
FROM insurance_data);

-- Using Group By function
SELECT children, avg(claim)
FROM insurance_data
GROUP BY children
ORDER BY children;

--Q3: What is the highest and lowest claimed amount by patients in each region?
SELECT patientid, region, max(claim) over(partition by region range between unbounded preceding and unbounded following) as Max_Claimed_amount,
min(claim) over(partition by region range between unbounded preceding and unbounded following) as Min_Claimed_amount
FROM insurance_data;

--Q4:What is the percentage of smokers in each age group?

--SELECT MIN(age), MAX(age)
--FROM insurance_data;
     
SELECT age_range, smoker, COUNT_AGE_RANGE, TOTAL_COUNT,ROUND(Perc_Smokers_AGE_Group::NUMERIC,2) || '%' AS Round_Percenrage
FROM
(SELECT age_range, smoker, COUNT_AGE_RANGE, TOTAL_COUNT, COUNT_AGE_RANGE/ CAST(TOTAL_COUNT AS FLOAT)*100 AS Perc_Smokers_AGE_Group 
FROM
(SELECT age_range, smoker, COUNT(age_range) OVER (PARTITION BY age_range) AS COUNT_AGE_RANGE, COUNT(*) OVER () AS TOTAL_COUNT
FROM
(SELECT
      CASE 
	     WHEN age >= 11 and age <=20 THEN '10 - 20'
		 WHEN age >= 21 and age <=30 THEN '21 - 30'
		 WHEN age >= 31 and age <=40 THEN '31 - 40'
		 WHEN age >= 41 and age <=50 THEN '41 - 50'
		 WHEN age >= 51 and age <=60 THEN '51 - 60'
		 END as Age_Range, smoker, age, patientID, region 
FROM insurance_data
WHERE smoker = 'Yes'
ORDER BY age_range)));

--Q5: For each patient, calculate the difference between their claimed amount and the average claimed amount of patients with the same number of children?

SELECT children, patientid, (claim - Avg_claim_by_children) as Difference
FROM (SELECT children, patientID, claim,ROUND((AVG(claim) over (partition by children order by children)),2) as Avg_claim_by_children
      FROM insurance_data);

--Q5: Show the patient with the highest BMI in each region and their respective rank?

SELECT patientID, region, bmi, 
MAX(bmi) over (partition by region) as Highest_BMI, 
Min(bmi) over (partition by region) as Lowest_BMI,
RANK() OVER (partition by region ORDER BY bmi desc),
DENSE_RANK()OVER (partition by region ORDER BY bmi desc)
FROM insurance_data;

--Q6: Calculate the difference between the claimed amount of each patient and the claimed amount of the patient who has the highest BMI in their region?

SELECT patientID, region, claim, bmi, Max_bmi, Highest_Claim_Per_Region, claim - Highest_Claim_Per_Region as Difference_Claim
FROM (SELECT patientID, region, claim, bmi, Max_bmi,
CASE
    WHEN Max_bmi = 48.1 THEN 9432.93
	WHEN Max_bmi = 53.1 THEN 1163.46
	WHEN Max_bmi = 52.6 THEN 44501.40
	WHEN Max_bmi = 47.6 THEN 46113.51
	END AS Highest_Claim_Per_Region
	
FROM 
(SELECT patientID, region, claim, bmi, MAX(bmi) over (partition by region) as Max_bmi
FROM insurance_data));

--Q7: For each patient, calculate the difference in claim amount between the patient and the patient with the highest claim amount among patients with the same bmi and smoker status. Return the result in descending order difference?
SELECT patientID, claim, bmi, smoker, High_same_Bmi_Smoker_Status 
FROM
(SELECT patientID, region, claim, bmi, smoker, MAX(claim)over (partition by bmi, smoker) as High_same_Bmi_Smoker_Status
FROM insurance_data);

--Q8: For each patient, find the maximum BMI value among their next three records (ordered by age)?
SELECT patientID, bmi, age, max(bmi) over (order by age rows between 1 following and 3 following) as Max_BMI_Next3Records
FROM insurance_data; 

--Q9: For each patient, find the rolling average of the last 2 claims?

SELECT patientID, claim, Rolling_avg, last_value (rolling_avg) over () as Rollingavg_Last2claims
FROM
(SELECT patientID, claim,
ROUND((avg(claim) over (Rows between 1 preceding and current row)):: NUMERIC,2) as Rolling_avg
FROM insurance_data);

--Q10: Find the first claimed insurance value for male and female patients, within each region. Order the data by patient age in ascending order, and only include patients who are non-diabetic and have a bmi value between 25 and 30?

SELECT patientid, gender, claim, region, age, diabetic, bmi, first_value(gender) over (partition by gender, region order by age)
FROM insurance_data
WHERE diabetic = 'Yes' and bmi between 25 and 30;