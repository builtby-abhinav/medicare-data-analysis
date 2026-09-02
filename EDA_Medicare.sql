-- ============================================================
-- EXPLORATORY DATA ANALYSIS (EDA)
-- Objective:
-- Explore the cleaned Medicare inpatient dataset to understand
-- provider performance, payment patterns, service utilization,
-- and cost variations through business-oriented SQL analysis.
-- ============================================================

-- Plan of Action
-- 1. Understand the overall dataset.
-- 2. Analyze distributions and summary statistics.
-- 3. Identify top and bottom performers.
-- 4. Compare payments, charges, and discharges.
-- 5. Analyze trends across states, cities, DRGs, and RUCA categories.
-- 6. Detect unusual or high-cost providers.
-- 7. Answer business-driven analytical questions.
-- 8. Generate insights for the Power BI dashboard.

-- View the cleaned dataset
		SELECT *
		FROM medicare_impatient;

-- ============================================================
-- #1 DATA OVERVIEW
-- Objective:
-- Understand the size and composition of the dataset before
-- performing detailed analysis.
-- ============================================================

-- Find the total number of records available
		SELECT
			COUNT(*)
		FROM medicare_impatient;

	-- Observation:
	-- Total records = 145,879

---------------------------------------------------------------

-- Compare the number of unique provider identifiers (CCN)
-- with the number of unique hospital names.
		SELECT
			COUNT(DISTINCT Rndrng_Prvdr_CCN) AS total_unique_ccn,
			COUNT(DISTINCT Rndrng_Prvdr_Org_Name) AS total_unique_hospital_names
		FROM medicare_impatient;

	-- Observation:
	-- Unique CCNs = 2,906
	-- Unique hospital names = 2,845
	-- Since the counts differ, further investigation is required.

---------------------------------------------------------------

-- Identify hospital names that are associated with
-- more than one unique CCN.
		SELECT
			Rndrng_Prvdr_Org_Name,
			COUNT(DISTINCT Rndrng_Prvdr_CCN) AS total_unique_ccn
		FROM medicare_impatient
		GROUP BY
			Rndrng_Prvdr_Org_Name
		HAVING COUNT(DISTINCT Rndrng_Prvdr_CCN) > 1
		ORDER BY
			total_unique_ccn DESC,
			Rndrng_Prvdr_Org_Name;

	-- Observation:
	-- 40 hospital names are associated with multiple CCNs.
	-- This indicates that hospitals sharing the same name
	-- exist as separate certified providers.
	-- Therefore, CCN will be treated as the unique provider identifier.

---------------------------------------------------------------

-- Determine the overall coverage of the dataset
-- across locations, diagnosis groups and RUCA classifications.
		SELECT
			COUNT(DISTINCT Rndrng_Prvdr_City) AS city,
			COUNT(DISTINCT Rndrng_Prvdr_State_Abrvtn) AS abr,
			COUNT(DISTINCT Rndrng_Prvdr_RUCA) AS ruca_ctgry,
			COUNT(DISTINCT Rndrng_Prvdr_RUCA_Desc) AS ruca_descrip,
			COUNT(DISTINCT DRG_Cd) AS drg_code,
			COUNT(DISTINCT DRG_Desc) AS descrip
		FROM medicare_impatient;

-- Observation:
	-- Total records            : 145,879
	-- Unique providers (CCN)   : 2,906
	-- Unique hospital names    : 2,845
	-- U.S. states covered      : 51
	-- Cities covered           : 1,762
	-- RUCA categories          : 19
	-- DRG diagnosis groups     : 540

-- ============================================================
-- #2 SUMMARY STATISTICS
-- Objective:
-- Analyze the numerical columns to understand their range,
-- central tendency, and overall distribution before performing
-- deeper business analysis.
-- ============================================================

	-- Discharges
		SELECT
			MIN(tot_dschrgs) AS Min_discharges,
			MAX(tot_dschrgs) AS Max_discharges,
			ROUND(AVG(tot_dschrgs)) AS Avg_discharges,

			MIN(avg_submtd_cvrd_chrg) AS Min_charged,
			MAX(avg_submtd_cvrd_chrg) AS Max_charged,
			ROUND(AVG(avg_submtd_cvrd_chrg)) AS Avg_charged,

			MIN(avg_tot_pymt_amt) AS Min_payed,
			MAX(avg_tot_pymt_amt) AS Max_payed,
			ROUND(AVG(avg_tot_pymt_amt)) AS Avg_payed,

			MIN(avg_mdcr_pymt_amt) AS Min_covered,
			MAX(avg_mdcr_pymt_amt) AS Max_covered,
			ROUND(AVG(avg_mdcr_pymt_amt)) AS Avg_covered
		FROM medicare_impatient;

-- Observation:
	-- Minimum discharges         : 11
	-- Maximum discharges         : 3,400
	-- Average discharges         : 34
	-- Minimum submitted charge   : $2,058.38
	-- Maximum submitted charge   : $7,196,636.94
	-- Average submitted charge   : $96,366
	-- Minimum total payment      : $1,849.08
	-- Maximum total payment      : $1,443,309.67
	-- Average total payment      : $19,151
	-- Minimum Medicare payment   : $386.80
	-- Maximum Medicare payment   : $1,436,667.83
	-- Average Medicare payment   : $15,783

-- Insights:
-- • Hospitals bill significantly more than they ultimately receive.
-- • Medicare payments constitute a major portion of the total payments received.
-- • Discharges and payment amounts vary widely across provider–DRG records.

-- Hospitals with the highest estimated Medicare payments
		SELECT 
			rndrng_prvdr_org_name AS hospital_name,
			SUM(tot_dschrgs*avg_mdcr_pymt_amt) AS medicare_cover
		FROM medicare_impatient
		GROUP BY
			rndrng_prvdr_org_name
		ORDER BY
		    medicare_cover DESC,
			hospital_name;
/* #1 New York-Presbyterian Hospital			 - 829191352.0006410
   #2 Nyu Langone Hospitals	 	            	 - 697439272.9989356
   #3 Stanford Health Care					     - 503479801.9998753
*/

-- DRG`s with highest average charges
		SELECT	
			ROUND(AVG(avg_submtd_cvrd_chrg),2) AS charges,
			drg_desc AS descriptiom_of_drg
		FROM medicare_impatient
		GROUP BY drg_desc
		ORDER BY charges DESC,
				 descriptiom_of_drg;
	-- #1  2276259.99 - "CHIMERIC ANTIGEN RECEPTOR (CAR) T-CELL AND OTHER IMMUNOTHERAPIES"
	-- #2  1569030.88 - "HEART TRANSPLANT OR IMPLANT OF HEART ASSIST SYSTEM WITH MCC"
	-- #3  1042550.67 - "LUNG TRANSPLANT"	
	-- Observation:
	-- CAR-T Cell and other Immunotherapies have the highest average submitted charges ($2.28M).
	-- Heart Transplant / Heart Assist System ranks second ($1.57M).
	-- Lung Transplant ranks third ($1.04M).

-- Cities with Higher patients (discharges)
		SELECT
			SUM(tot_dschrgs) AS discharges,
			rndrng_prvdr_state_abrvtn AS state,
			rndrng_prvdr_city AS city
		FROM medicare_impatient
		GROUP BY 
			rndrng_prvdr_state_abrvtn,
			rndrng_prvdr_city
		ORDER BY
			discharges DESC,
			state,
			city;
	-- 80265	"NY"	"New York"
	-- 43818	"MA"	"Boston"
    -- 42159	"FL"	"Orlando"
	---- Insight:
	-- Large metropolitan cities account for the highest patient volumes,
	-- indicating greater healthcare demand and hospital capacity.

-- states having most providers (hospitals)
		SELECT
			rndrng_prvdr_state_abrvtn AS state,
			COUNT(DISTINCT rndrng_prvdr_ccn ) AS providers
		FROM medicare_impatient
		GROUP BY
			rndrng_prvdr_state_abrvtn
		ORDER BY
			providers DESC,
			state;
	-- "CA"	272
	-- "TX"	241
	-- "FL"	165
	--
	-- Insight:
	-- California, Texas, and Florida have the largest Medicare provider networks,
	-- indicating broader healthcare infrastructure and provider availability.

-- diagnoses with the highest reimbursements
		SELECT 
		    DISTINCT drg_desc AS condition_description,
			SUM (tot_dschrgs * avg_mdcr_pymt_amt) AS reimbursements
		FROM medicare_impatient
		GROUP BY 
			drg_desc
		ORDER BY 
			reimbursements DESC,
			condition_description;
			
	-- "SEPTICEMIA OR SEVERE SEPSIS WITHOUT MV >96 HOURS WITH MCC"	8959316640.0046561
	-- "INFECTIOUS AND PARASITIC DISEASES WITH O.R. PROCEDURES WITH MCC"	3226700445.999262
	-- "HEART FAILURE AND SHOCK WITH MCC"	3053746234.9965452
	-- Insight:
	-- High-volume, high-cost critical conditions account for the largest share of Medicare reimbursements.

-- Highest average total payments by DRG
		SELECT
			DISTINCT drg_desc AS condition_description,
			ROUND (AVG(avg_tot_pymt_amt)) AS payed_amt
		FROM medicare_impatient
		GROUP BY 
			drg_desc
		ORDER BY 
			payed_amt DESC,
			condition_description;
-- Observation:
	-- CAR-T Cell and other Immunotherapies received the highest average total payment ($469,787).
	-- Heart Transplant / Heart Assist System ranked second ($341,048).
	-- ECMO or Tracheostomy with prolonged mechanical ventilation ranked third ($220,889).
-- Insight:
	-- Highly complex and resource-intensive procedures receive the highest average total payments.

-- Highest average total medicare_reimbursements by DRG
		SELECT
			DISTINCT drg_desc AS condition_description,
			ROUND (AVG(avg_mdcr_pymt_amt)) AS reimbursements
		FROM medicare_impatient
		GROUP BY 
			drg_desc
		ORDER BY 
			reimbursements DESC,
			condition_description;
-- Observation:
	-- CAR-T Cell and other Immunotherapies received the highest average Medicare reimbursement ($437,173).
	-- Heart Transplant / Heart Assist System ranked second ($286,685).
	-- ECMO or Tracheostomy with prolonged mechanical ventilation ranked third ($189,249).

-- Insight:
	-- Medicare reimburses the highest amounts for highly specialized and resource-intensive treatments.

	-- Key Insight:
	-- The average Medicare reimbursement is very close to the average total payment for the highest-cost DRGs.
	-- This suggests that Medicare covers a substantial portion of the costs associated with these high-cost diagnoses.

-- Hospitals with highest average submitted charges
		SELECT
			DISTINCT rndrng_prvdr_ccn AS Hospital_Id,
			rndrng_prvdr_org_name AS Hospital_name,
			ROUND(AVG(avg_submtd_cvrd_chrg),2) AS BILL
		FROM medicare_impatient
		GROUP BY
			rndrng_prvdr_ccn,
			rndrng_prvdr_org_name
		ORDER BY 
			BILL DESC,
			Hospital_name;

--	Top 5 hospitals with the highest average difference between billed amount and total payment received.
		SELECT
			AVG(avg_submtd_cvrd_chrg) AS Billed,
			AVG(avg_tot_pymt_amt) AS paid_to_hospital,
			AVG (avg_submtd_cvrd_chrg - avg_tot_pymt_amt) AS Margin,
			rndrng_prvdr_ccn AS Hospital_id,
			rndrng_prvdr_org_name AS Hospital_name
		FROM medicare_impatient
		GROUP BY rndrng_prvdr_org_name,
				 rndrng_prvdr_ccn
		ORDER BY Margin DESC,
				 Hospital_name
		LIMIT 5;
/*
   Observation:
   The average billed amount is significantly higher than the average payment received across all top five hospitals.
   Rush Specialty Hospital records the highest average billed amount as well as the largest average billing-payment margin.
   Although the hospitals ranked 3rd, 4th, and 5th have slightly lower margins than the top two,
   they still exhibit a substantial gap between billed and paid amounts.
   
   Insight:
   Hospitals consistently bill considerably more than the amount they ultimately receive as payment, 
   indicating significant reimbursement adjustments.
   A lower rank in this analysis does not necessarily imply lower billing; 
   it simply reflects a smaller average billing-payment margin compared to the hospitals ranked above.	
*/

--	Top 5 DRG (Diagnosis) with the highest average difference between billed amount and total payment received.
		SELECT
			ROUND(AVG(avg_submtd_cvrd_chrg),2) AS Billed,
			ROUND(AVG(avg_tot_pymt_amt),2) AS paid_to_hospital,
			ROUND(AVG (avg_submtd_cvrd_chrg - avg_tot_pymt_amt),2) AS Margin,
			drg_cd AS Diagnosis_id,
			drg_desc AS Duagnosis_name
		FROM medicare_impatient
		GROUP BY drg_desc,
				 drg_cd
		ORDER BY Margin DESC,
				 Duagnosis_name
		LIMIT 5;
/*
   Observation:
   • CAR-T Cell and other Immunotherapies has the highest average billed amount,
     average payment received, and average billing-payment margin.
   • All top five diagnoses are high-cost transplant or critical care procedures.
   • A substantial gap exists between the average billed amount and the average
     payment received for each of the top five diagnoses.

   Insight:
   • High-cost transplant and critical care procedures are associated with the
     largest average billing-payment margins.
   • The average payment received remains significantly lower than the average
     billed amount across all top five diagnoses.
*/

-- Do hospitals with high discharges have higher medicare_payments ? lets find out
		SELECT
			rndrng_prvdr_org_name AS Hospital,
			SUM(tot_dschrgs) AS total_Discharges,
			SUM(tot_dschrgs * avg_mdcr_pymt_amt) AS Medicare_payment
		FROM medicare_impatient
		GROUP BY rndrng_prvdr_org_name
		ORDER BY total_Discharges DESC,
				 Hospital
		LIMIT 5;

/*
   Observation:
   • AdventHealth Orlando has the highest total discharges among the top five
     hospitals.
   • New York-Presbyterian Hospital records the highest estimated Medicare
     payment despite having fewer total discharges than AdventHealth Orlando.
   • NYU Langone Hospitals ranks third in total discharges but second in
     estimated Medicare payment.
   • Higher total discharges do not consistently result in higher estimated
     Medicare payments.

   Insight:
   • Total Medicare payment is influenced by both the number of discharges and
     the Medicare payment received per discharge.
   • A higher discharge volume alone does not guarantee the highest total
     Medicare payment.
*/

-- Ranking hospitals by medicare payments in each state
WITH Top_Hospitals AS(
		SELECT
			rndrng_prvdr_state_abrvtn AS state,
			rndrng_prvdr_org_name AS Hospital_name,
			SUM(tot_dschrgs * avg_mdcr_pymt_amt) AS total,
			RANK()OVER(
				PARTITION BY rndrng_prvdr_state_abrvtn
				ORDER BY SUM(tot_dschrgs * avg_mdcr_pymt_amt) DESC
			) AS Hospital_rank
		FROM medicare_impatient
		GROUP BY 
			rndrng_prvdr_state_abrvtn,
			rndrng_prvdr_org_name
		)

		SELECT
			state,
			Hospital_name,
			Hospital_rank
		FROM Top_Hospitals
		WHERE Hospital_rank <=3 
		ORDER BY state,
				 hospital_rank;
/*
   Observation:
   • The query ranks the top three hospitals by estimated Medicare payments
     within each state.
   • Every state has its own independent ranking, ensuring hospitals are
     compared only with others in the same state.
   • Several nationally recognized academic and tertiary-care hospitals rank
     first in their respective states.

   Insight:
   • The leading Medicare payment recipients differ across states, indicating
     that healthcare spending is distributed among state-specific referral
     centers rather than a few nationwide hospitals.
   • Window functions enable state-level rankings without losing the detailed
     hospital-level information.
*/

-- ANALYISI BY RUCA categories
-- How do Medicare payments vary across different RUCA classifications?
		SELECT
			rndrng_prvdr_ruca_desc AS RUCA_category,
			ROUND(AVG(avg_mdcr_pymt_amt)) AS Avg_payment
		FROM medicare_impatient
		GROUP BY 
			rndrng_prvdr_ruca_desc
		ORDER BY 
			RUCA_category;

-- Lets categorize them
	SELECT
		CASE
			WHEN rndrng_prvdr_ruca_desc  ILIKE 'Metropolitan%' THEN  'Metropolitan'
			WHEN rndrng_prvdr_ruca_desc  ILIKE 'Micropolitan%' THEN  'Micropolitan'
			WHEN rndrng_prvdr_ruca_desc  ILIKE 'small town%'   THEN  'Small Town'
			WHEN rndrng_prvdr_ruca_desc  ILIKE 'rural%' 		 THEN  'Rural'
			ELSE 'Unknown'
		END AS RUCA_categories,
			ROUND(AVG(avg_mdcr_pymt_amt)) AS Avg_payment
		FROM medicare_impatient
		GROUP BY 
			RUCA_categories
		ORDER BY 
			Avg_payment DESC;
/*
   Insight:
   • Providers located in metropolitan areas tend to receive higher average
     Medicare payments than providers in micropolitan, small town, and rural
     areas.
   • The level of urbanization appears to be associated with differences in
     average Medicare reimbursement.
*/