
/***BE SURE TO DROP ALL TABLES IN WORK THAT BEGIN WITH "CASE_"***/

/*Set Time Zone*/
set time_zone='-4:00';
select now();

/***PRELIMINARY ANALYSIS***/

/*Create a VIEW in WORK called CASE_SCOOT_NAMES that is a subset of the prod table
which only contains scooters.
Result should have 7 records.*/

CREATE OR REPLACE VIEW work.case_scoot_names AS
SELECT * from ba710case.ba710_prod
where product_type = 'scooter';

select * from work.case_scoot_names;

/*The following code uses a join to combine the view above with the sales information.
  Can the expected performance be improved using an index?
  A) Calculate the EXPLAIN COST.
  B) Create the appropriate indexes.
  C) Calculate the new EXPLAIN COST.
  D) What is your conclusion?:
*/

select a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, date(b.sales_transaction_date) as sale_date,
    b.sales_amount, b.channel, b.dealership_id
from work.case_scoot_names a 
inner join ba710case.ba710_sales b
    on a.product_id=b.product_id;

/*A) Calculate the EXPLAIN COST.*/
explain format = json 
select  a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, date(b.sales_transaction_date) as sale_date,
    b.sales_amount, b.channel, b.dealership_id
from work.case_scoot_names a 
inner join ba710case.ba710_sales b
    on a.product_id=b.product_id;

/*ANSWER: The cost is 4580.01 */

/*B) Create the appropriate indexes.*/
drop index  idx_prodid on ba710case.ba710_sales;
create index idx_prodid on ba710case.ba710_sales (product_id);

/*C) Calculate the new EXPLAIN COST.*/
explain format = json 
select a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, date(b.sales_transaction_date) as sale_date,
    b.sales_amount, b.channel, b.dealership_id
from work.case_scoot_names a 
inner join ba710case.ba710_sales b
    on a.product_id=b.product_id;

/*ANSWER: the cost with the index is 615.04*/

/*D) What is your conclusion?:*/

/*ANSWER: The index helps in reducing the speed and cost of the query because with the index it evalautes 3425 rows while without the index it evaluates every row.*/

/***PART 1: INVESTIGATE BAT SALES TRENDS***/  
    
/*The following creates a table of daily sales with four columns and will be used in the following step.*/
DROP TABLE IF EXISTS WORK.case_daily_sales;
CREATE TABLE work.case_daily_sales AS
	select p.model, p.product_id, date(s.sales_transaction_date) as sale_date, 
		   round(sum(s.sales_amount),2) as daily_sales
	from ba710case.ba710_sales as s 
    inner join ba710case.ba710_prod as p
		on s.product_id=p.product_id
    group by date(s.sales_transaction_date),p.product_id,p.model;

select * from work.case_daily_sales;

/*Create a view (5 columns) of cumulative sales figures for just the Bat scooter from
the daily sales table you created.
Using the table created above, add a column that contains the cumulative
sales amount (one row per date).
Hint: Window Functions, Over*/
CREATE OR REPLACE VIEW work.case_sales_scoot_bat AS
select *, 
round(sum(daily_sales) over(order by sale_date rows between unbounded preceding and current row ),2) as cumulative_Sales
from work.case_daily_sales
	where model = 'Bat';

select *  from work.case_sales_scoot_bat;
/*Using the view above, create a VIEW (6 columns) that computes the cumulative sales 
for the previous 7 days for just the Bat scooter. 
(i.e., running total of sales for 7 rows inclusive of the current row.)
This is calculated as the 7 day lag of cumulative sum of sales
(i.e., each record should contain the sum of sales for the current date plus
the sales for the preceeding 6 records).
*/
CREATE OR REPLACE VIEW work.case_sales_scoot_bat AS
select *,
round(sum(daily_sales) over(order by sale_date rows between unbounded preceding and current row ),2) as cumulative_Sales,
round(sum(daily_Sales) over(rows between 6 preceding and current row),2) as cumu_Sales_7_days
from work.case_daily_sales
	where model = 'Bat';

select *  from work.case_sales_scoot_bat;
/*Using the view you just created, create a new view (7 columns) that calculates
the weekly sales growth as a percentage change of cumulative sales
compared to the cumulative sales from the previous week (seven days ago).

See the Word document for an example of the expected output for the Blade scooter.*/

CREATE OR REPLACE VIEW work.case_sales_scoot_bat AS
select *,
round(sum(daily_sales) over(order by sale_date rows between unbounded preceding and current row ),2) as cumulative_Sales,
round(sum(daily_Sales) over(rows between 6 preceding and current row),2) as cumu_Sales_7_days,
round(((sum(daily_sales) over(rows between unbounded preceding and current row) - sum(daily_Sales) over(rows between unbounded preceding and 7 preceding))/sum(daily_Sales) over(rows between unbounded preceding and 7 preceding))*100,2) as percentage
from work.case_daily_sales
	where model = 'Bat';
    
select *  from work.case_sales_scoot_bat;

/*Paste a screenshot of at least the first 10 records of the table
  and answer the questions in the Word document*/
  
  
  

/*********************************************************************************************
Is the launch timing (October) a potential cause for the drop?

/*ANSWER: THE LAUNCH TIMING COULD NOT BE A POTENTIAL CAUSE FOR THE DROP; THE NORMAL BEHAVIOUR IN A PRODUCT LIFE CYCLE COULD BE THE POTENTIAL CAUSE FOR THE DROP BECAUSE THE SALES INCREASE AT THE FIRST STAGES OF THE CYCLE AND IT DECLINES OVER TIME*/

/*Replicate the Bat sales cumulative analysis for the Bat Limited Edition.
*/

CREATE OR REPLACE VIEW work.case_sales_scoot_bat_limited AS
select *,
round(sum(daily_sales) over(order by sale_date rows between unbounded preceding and current row ),2) as cumulative_Sales,
round(sum(daily_Sales) over(rows between 6 preceding and current row),2) as cumu_Sales_7_days,
round(((sum(daily_sales) over(rows between unbounded preceding and current row) - sum(daily_Sales) over(rows between unbounded preceding and 7 preceding))/sum(daily_Sales) over(rows between unbounded preceding and 7 preceding))*100,2) as percentage
from work.case_daily_sales
	where model = 'Bat Limited Edition';
    
select *  from work.case_sales_scoot_bat_limited;

/*Paste a screenshot of at least the first 10 records of the table
  and answer the questions in the Word document*/

/*********************************************************************************************
However, the Bat Limited was at a higher price point.
Let's take a look at the 2013 Lemon model, since it's a similar price point.  
Is the launch timing (October) a potential cause for the drop?

/*ANSWER: COMPARING THE TWO BEHAVOIURS OF THE MODELS, WE COULD SAY THAT THE LAUNCH TIMING IS NOT A POTENTIAL CAUSE FOR THE DROP, SINCE MODELS HACE A SIMILAR BEHAVIOURS, STAERTING WITH A HIGH SALES GRWOTH AND DECLINE IT OVER TIME */

/*Replicate the Bat sales cumulative analysis for the 2013 Lemon model.*/

CREATE OR REPLACE VIEW work.case_sales_scoot_lemon AS
select *,
round(sum(daily_sales) over(order by sale_date rows between unbounded preceding and current row ),2) as cumulative_Sales,
round(sum(daily_Sales) over(rows between 6 preceding and current row),2) as cumu_Sales_7_days,
round(((sum(daily_sales) over(rows between unbounded preceding and current row) - sum(daily_Sales) over(rows between unbounded preceding and 7 preceding))/sum(daily_Sales) over(rows between unbounded preceding and 7 preceding))*100,2) as percentage
from work.case_daily_sales
	where product_id = 3;
    
select *  from work.case_sales_scoot_lemon
/*Paste a screenshot of at least the first 10 records of the table
  and answer the questions in the Word document*/

