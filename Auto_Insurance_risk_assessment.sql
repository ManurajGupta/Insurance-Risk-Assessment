-- *** PROJECT BASED QUESTIONS ***


-- 1. What % of the customers have made a claim in the current exposure period?

-- There are customers who have claimed more than once and these are counted only once in the % calculation.
select (select count(*) from auto_insurance_risk where ClaimNb > 0)/count(*) *100 as claim_perc 
from auto_insurance_risk;  


-- #2. 2.1. Create a new column as 'claim_flag' in the table 'auto_insurance_risk' as integer datatype.

ALTER TABLE auto_insurance_risk ADD COLUMN claim_flag INT;

-- 2.2. Set the value to 1 when ClaimNb is greater than 0 and set the value to 0 otherwise.

UPDATE auto_insurance_risk set claim_flag=
	(CASE 
		WHEN ClaimNb > 0 THEN 1
		ELSE 0
	END);
 

-- #3. What is the average exposure period for those who have claimed vs not claimed? 

SELECT claim_flag, round(avg(Exposure),3) as Avg_exposure 
FROM auto_insurance_risk 
GROUP BY claim_flag; 

-- INFERENCE: The customers who have claimed insurance have greater average exposure. 
-- Thus, exposure is a good variable to predict the chances of whether a claim would be made by a customer or not.



-- #4. Create an exposure bucket where buckets are like below
-- Buckets are => E1 = 0 to 0.25, E2 = 0.26 to 0.5, E3 = 0.51 to 0.75, E4 > 0.75,


-- Before creating buckets, rounding the exposure to two decimal places:
ALTER table auto_insurance_risk add column round_exp double; 
-- This new column named 'round_exp' will be used in further queries

-- Updating values in column 'round_exp'
UPDATE auto_insurance_risk SET round_exp = round(exposure,2);

-- Creating exposure buckets:
ALTER table auto_insurance_risk add column exp_bucket varchar(5); 

-- Updating values in column 'exp_bucket'
UPDATE auto_insurance_risk set exp_bucket=
 	(CASE 
		WHEN round_exp <= 0.25 THEN 'E1'
        WHEN round_exp BETWEEN 0.26 AND 0.5 THEN 'E2'
		WHEN round_exp BETWEEN 0.51 AND 0.75 THEN 'E3'
		ELSE 'E4'
	END);
    
-- 4.2
--  What is the % of total claims by these buckets? What do you infer from the summary? (consider ClaimNb field to get the total claim count)
select exp_bucket, sum(ClaimNb)/(select sum(ClaimNb) from auto_insurance_risk)*100 as claim_perc 
from auto_insurance_risk
group by exp_bucket
order by claim_perc DESC;

-- INFERENCE: The highest no of claims have been made in the highest exposure bucket(E4), 
-- hence greater the exposure, more the chances of a claim being made.
-- In cases where exposure falls under E4 bucket, a higher insurance premium should be charged.


-- 5. Which area has the higest number of average claims (in percentage)?

Select area, sum(ClaimNb)/count(IDpol) *100 AS claim_perc from auto_insurance_risk
group by area
order by claim_perc DESC; 
-- AREA F has the highest number of avg claims w.r.t. no. of policies

-- 6.Is there any pattern if we look at the claim rate using the exposure buckets along with Area i.e. group Area and Exposure 
-- Buckets together.

select area, exp_bucket, (sum(claim_flag)/count(*))*100 as claim_rate from auto_insurance_risk
group by area, exp_bucket
order by claim_rate DESC;
-- E4 bucket of Area F has the highest claim rate. Top three claim rates are all from E4 buckets of Area F,E,D. 
-- Within each area, Claim_rate increases with increase in exp_bucket

-- #7. 7.1. What is the average Vehicle Age for those who claimed vs those who didn't claim?

select avg(vehage), claim_flag from auto_insurance_risk
group by claim_flag;
-- Average vehicle age of those who claimed is lesser as compared to those who didn't claim.


-- 7.2. Is there any pattern observed if we calculate the average Vehicle Age for those who claimed and group 
-- them by Area?
select Area, avg(vehage) as avg_age from auto_insurance_risk
where claim_flag=1
group by Area
order by avg_age; 
-- INFERENCE : Area F which had the highest no. of avg claims also has average age of cars as lowest. 
-- Area A having lowest avg claims has highest avg age of cars. Hence, these two parameters are inversely related.

-- #8. If we calculate the average vehicle age by exposure bucket, 
-- do we see a trend between those who claimed vs those who didn't?

select exp_bucket,claim_flag, avg(vehage) as avg_age from auto_insurance_risk
group by exp_bucket,claim_flag
order by exp_bucket;
-- For a given bucket, average age of cars is higher for those who did not claim as compared to those who claimed. 
-- E4 bucket has highest average age of cars.

-- #9. 9.1. Create a Claim_Ct flag on the ClaimNb field as below, and take average of the BonusMalus by Claim_Ct.
-- Note: Claim_Ct = '1 Claim' where ClaimNb = 1, Claim_Ct = 'MT 1 Claims' where ClaimNb > 1, Claim_Ct = 'No Claims' where ClaimNb = 0. 
-- 9.2. What is the inference from the summary? 


ALTER table auto_insurance_risk add column Claim_Ct varchar(20);

-- Updating values
UPDATE auto_insurance_risk set Claim_Ct=
	(CASE 
		WHEN ClaimNb = 0 THEN 'No Claims'
		WHEN ClaimNb = 1 THEN '1 Claim'
		ELSE 'MT 1 Claims'
	END);

select Claim_Ct, avg(BonusMalus) as avg_BM from auto_insurance_risk
group by Claim_Ct
order by avg_BM;
-- 9.2 INFERENCE: Bonus malus increases with an increase in the number of claims.

-- #10. Using the same Claim_Ct created above, if we aggregate the Density column (take average) by Claim_Ct, 
-- what inference can we make from the summary data?

select Claim_Ct, avg(Density) as avg_density from auto_insurance_risk
group by Claim_Ct
order by avg_density;
-- INFERENCE: The no. of claims is directly related to the density of the inhabitants in a city...
-- Higher density (>2000) implies more likelihood of more than one claims.
-- Thus, an increased premium should be charged for the drivers living in cities with greater avg_density. 

-- #11. Which Vehicle Brand & Vehicle Gas combination have the highest number of Average Claims ?

select VehBrand, VehGas, avg(claimnb) as avg_claims from auto_insurance_risk
group by VehBrand, VehGas
order by avg_claims DESC;
-- B12 Regular has highest number of avg claims per policy =0.0639 or 6.39%

-- #12. List the Top 5 Regions & Exposure bucket Combination from Claim Rate's perspective. 

select region, exp_bucket, sum(claim_flag)/count(*) *100 as claim_rate from auto_insurance_risk
group by region, exp_bucket
order by claim_rate DESC
LIMIT 5;

-- #13. 13.1. Are there any cases of illegal driving i.e. underaged folks driving and 
-- committing accidents?

select * from auto_insurance_risk
where DrivAge < 18 AND claim_flag=1;
-- Zero such cases of illegal driving found

-- 13.2. Create a bucket on DrivAge and then take average of BonusMalus by this Age Group Category. WHat do you infer from the summary? 
-- Note: DrivAge=18 then 1-Beginner, DrivAge<=30 then 2-Junior, DrivAge<=45 then 3-
-- Middle Age, DrivAge<=60 then 4-Mid-Senior, DrivAge>60 then 5-Senior

alter table auto_insurance_risk add column DrivAge_bkt varchar(50);
update auto_insurance_risk set DrivAge_bkt=
 	(CASE 
 		WHEN DrivAge = 18 THEN '1-Beginner'
        WHEN DrivAge <=30 THEN '2-Junior'
        WHEN DrivAge <=45 THEN '3-Middle Age'
		WHEN DrivAge <=60 THEN '4-Mid-Senior'
 		ELSE '5-Senior'
 	END);

select DrivAge_bkt, avg(BonusMalus) as avg_BM from auto_insurance_risk
group by DrivAge_bkt
order by avg_BM;
-- INFERENCE: The avg bonusmalus decreases with an increase in age. 
-- The bonusmalus is high for driver age buckets having driver age less than 30yrs i.e. Beginner and Junior categories
