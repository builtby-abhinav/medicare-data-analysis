-- Healthcare Cost Analytics: Medicare Hospital Payment & Utilization Analysis
-- Objective: Analyze Medicare inpatient hospital payment and utilization data
-- to identify cost patterns, provider performance, and healthcare insights
-- using SQL through data cleaning, exploratory data analysis (EDA), and
-- business-driven analytical queries.

		CREATE TABLE raw_medicare_impatient (
					Rndrng_Prvdr_CCN 			TEXT,
					Rndrng_Prvdr_Org_Name 		TEXT,
					Rndrng_Prvdr_City			TEXT,
					Rndrng_Prvdr_St				TEXT,
					Rndrng_Prvdr_State_FIPS 	TEXT,
					Rndrng_Prvdr_Zip5			TEXT,
					Rndrng_Prvdr_State_Abrvtn	TEXT,
					Rndrng_Prvdr_RUCA			TEXT,
					Rndrng_Prvdr_RUCA_Desc		TEXT,
					DRG_Cd						TEXT,
					DRG_Desc					TEXT,
					Tot_Dschrgs					TEXT,
					Avg_Submtd_Cvrd_Chrg		TEXT,
					Avg_Tot_Pymt_Amt			TEXT,
					Avg_Mdcr_Pymt_Amt 			TEXT
		);

		SELECT
			   COUNT(*)
			   FROM raw_medicare_impatient;
	-- Observed count of 145879
	
-- Now we create a copy of the original "raw_medicare_impatient" table
-- Coz we can trace back to source if anything goes wrong
-- We name the copied table as 'medicare_impatient_pack' (cantains everything)

		CREATE TABLE 
					medicare_impatient_pack (
					LIKE raw_medicare_impatient INCLUDING ALL
					);

		INSERT INTO 
					medicare_impatient_pack
					SELECT *
					FROM raw_medicare_impatient;
					
	-- lets verify the count with the original
		SELECT
			   COUNT(*)
			   FROM medicare_impatient_pack;
	-- Observed count of 145879 = raw

-- both row count matched that means everthing came up nice and clean ✅
-- LOCATING DUPLICATES
		SELECT*,
				ROW_NUMBER() OVER(
				PARTITION BY Rndrng_Prvdr_CCN,
							 Rndrng_Prvdr_Org_Name,
							 Rndrng_Prvdr_City,
							 Rndrng_Prvdr_St,
							 Rndrng_Prvdr_State_FIPS,
							 Rndrng_Prvdr_Zip5,
							 Rndrng_Prvdr_State_Abrvtn,
							 Rndrng_Prvdr_RUCA,
							 Rndrng_Prvdr_RUCA_Desc,
							 DRG_Cd,
							 DRG_Desc,
							 Tot_Dschrgs,
							 Avg_Submtd_Cvrd_Chrg,
							 Avg_Tot_Pymt_Amt,
							 Avg_Mdcr_Pymt_Amt 
							 ORDER BY Rndrng_Prvdr_CCN) AS row_num
							 FROM medicare_impatient_pack;

		WITH CTE AS (
				SELECT*,
				ROW_NUMBER() OVER(
				PARTITION BY Rndrng_Prvdr_CCN,
							 Rndrng_Prvdr_Org_Name,
							 Rndrng_Prvdr_City,
							 Rndrng_Prvdr_St,
							 Rndrng_Prvdr_State_FIPS,
							 Rndrng_Prvdr_Zip5,
							 Rndrng_Prvdr_State_Abrvtn,
							 Rndrng_Prvdr_RUCA,
							 Rndrng_Prvdr_RUCA_Desc,
							 DRG_Cd,
							 DRG_Desc,
							 Tot_Dschrgs,
							 Avg_Submtd_Cvrd_Chrg,
							 Avg_Tot_Pymt_Amt,
							 Avg_Mdcr_Pymt_Amt 
							 ORDER BY Rndrng_Prvdr_CCN) AS row_num
							 FROM medicare_impatient_pack
				 )
				 SELECT *
		 				FROM CTE
						WHERE row_num > 1;
						
	-- SINCE THERE ARE NO DUPLICATES WE EXERCISE THIS TABLE
		ALTER TABLE medicare_impatient_pack
		RENAME TO medicare_impatient;
		
-- LET'S REMOVE LEADING/TRAILING SPACES
		UPDATE medicare_impatient
				SET
				    Rndrng_Prvdr_CCN          = TRIM(Rndrng_Prvdr_CCN),
				    Rndrng_Prvdr_Org_Name     = TRIM(Rndrng_Prvdr_Org_Name),
				    Rndrng_Prvdr_City         = TRIM(Rndrng_Prvdr_City),
				    Rndrng_Prvdr_St           = TRIM(Rndrng_Prvdr_St),
				    Rndrng_Prvdr_State_FIPS   = TRIM(Rndrng_Prvdr_State_FIPS),
				    Rndrng_Prvdr_Zip5         = TRIM(Rndrng_Prvdr_Zip5),
				    Rndrng_Prvdr_State_Abrvtn = TRIM(Rndrng_Prvdr_State_Abrvtn),
				    Rndrng_Prvdr_RUCA         = TRIM(Rndrng_Prvdr_RUCA),
				    Rndrng_Prvdr_RUCA_Desc    = TRIM(Rndrng_Prvdr_RUCA_Desc),
				    DRG_Cd                    = TRIM(DRG_Cd),
				    DRG_Desc                  = TRIM(DRG_Desc),
				    Tot_Dschrgs               = TRIM(Tot_Dschrgs),
				    Avg_Submtd_Cvrd_Chrg      = TRIM(Avg_Submtd_Cvrd_Chrg),
				    Avg_Tot_Pymt_Amt          = TRIM(Avg_Tot_Pymt_Amt),
				    Avg_Mdcr_Pymt_Amt         = TRIM(Avg_Mdcr_Pymt_Amt);

-- Lets check for the NULL values
		SELECT *
				FROM medicare_impatient
				WHERE  Rndrng_Prvdr_CCN IS NULL OR
							 Rndrng_Prvdr_Org_Name IS NULL OR
							 Rndrng_Prvdr_City IS NULL OR
							 Rndrng_Prvdr_St IS NULL OR
							 Rndrng_Prvdr_State_FIPS IS NULL OR
							 Rndrng_Prvdr_Zip5 IS NULL OR
							 Rndrng_Prvdr_State_Abrvtn IS NULL OR
							 Rndrng_Prvdr_RUCA IS NULL OR
							 Rndrng_Prvdr_RUCA_Desc IS NULL OR
							 DRG_Cd IS NULL OR
							 DRG_Desc IS NULL OR
							 Tot_Dschrgs IS NULL OR
							 Avg_Submtd_Cvrd_Chrg IS NULL OR
							 Avg_Tot_Pymt_Amt IS NULL OR
							 Avg_Mdcr_Pymt_Amt IS NULL;
	-- seems like there are no Nulls in there

-- Lets check out the numerical valued column with non numeric symbols etc 
-- Lets check out the numerical valued column with non numeric symbols etc 
		SELECT	
				Tot_Dschrgs,
				Avg_Submtd_Cvrd_Chrg,
				Avg_Tot_Pymt_Amt,
				Avg_Mdcr_Pymt_Amt
			FROM medicare_impatient
			WHERE 
					Tot_Dschrgs !~ '^[0-9]+(\.[0-9]+)?$'
				 OR Avg_Submtd_Cvrd_Chrg !~ '^[0-9]+(\.[0-9]+)?$'
				 OR	Avg_Tot_Pymt_Amt !~ '^[0-9]+(\.[0-9]+)?$'
				 OR	Avg_Mdcr_Pymt_Amt !~ '^[0-9]+(\.[0-9]+)?$'

		SELECT 
				DISTINCT Rndrng_Prvdr_CCN,
						 Rndrng_Prvdr_Org_Name,
						 Rndrng_Prvdr_City,
						 Rndrng_Prvdr_St,
						 Rndrng_Prvdr_State_FIPS,
						 Rndrng_Prvdr_Zip5,
						 Rndrng_Prvdr_State_Abrvtn,
						 Rndrng_Prvdr_RUCA,
						 Rndrng_Prvdr_RUCA_Desc,
						 DRG_Cd,
						 DRG_Desc,
						 Tot_Dschrgs,
						 Avg_Submtd_Cvrd_Chrg,
						 Avg_Tot_Pymt_Amt,
						 Avg_Mdcr_Pymt_Amt 
				   FROM  medicare_impatient;

-- Lets validate the structure of the following
		SELECT DISTINCT Rndrng_Prvdr_St
					FROM medicare_impatient
					ORDER BY Rndrng_Prvdr_St;

-- Lets change the datatypes
	-- forst deal with those on which we calculate

	ALTER TABLE medicare_impatient
		ALTER COLUMN tot_dschrgs		  TYPE INTEGER
			USING tot_dschrgs::INTEGER,
		ALTER COLUMN avg_mdcr_pymt_amt	  TYPE NUMERIC
			USING avg_mdcr_pymt_amt::NUMERIC,
		ALTER COLUMN avg_submtd_cvrd_chrg TYPE NUMERIC
			USING avg_submtd_cvrd_chrg::NUMERIC,
		ALTER COLUMN avg_tot_pymt_amt	  TYPE NUMERIC
			USING avg_tot_pymt_amt::NUMERIC;

-- Lets deal with the other set

		ALTER TABLE medicare_impatient
			ALTER COLUMN drg_cd 	TYPE INTEGER
				USING drg_cd::INTEGER,
			ALTER COLUMN rndrng_prvdr_org_name

-- Check the data_types

		SELECT
			column_name,
			data_type
			FROM information_schema.columns
			WHERE table_name = 'medicare_impatient'
			ORDER BY ordinal_position;

-- Data Cleaning is  done 
-- Lets perform the Exploratory Data Analysis (EDA).