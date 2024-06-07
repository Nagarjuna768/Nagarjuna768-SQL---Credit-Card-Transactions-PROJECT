-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 

select*
from credit_card_transactions;



-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte1 as (select city,sum(amount) as cityspend
from credit_card_transactions
group by city),

cte2 as (select*,
dense_rank()over(order by cityspend desc) as highest_spend
from cte1),

cte3 as (select*
from cte2
where highest_spend<=5),

cte4 as(select sum(amount) as totalspend
from credit_card_transactions)

select cte3.*,round(cityspend/totalspend*100,3) as percentage
from cte4 
inner join cte3 
on 1=1;



-- 2- write a query to print highest spend month for each year and amount spent in that month for each card type


with cte1 as (select card_type,month(transaction_date)as mn,year(transaction_date) as yr,sum(amount) as totalspend
from credit_card_transactions
group by card_type,month(transaction_date),year(transaction_date)
order by month(transaction_date),year(transaction_date)),

cte2 as (select*,
dense_rank()over(partition by card_type order by totalspend desc) as rn
from cte1)

select*
from cte2
where rn=1;


-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type.)
with cte1 as (select*,sum(amount)over(partition by card_type order by transaction_id,transaction_date) as cum_spend
from credit_card_transactions),
 cte2 as (select*,
 dense_rank()over(partition by card_type order by cum_spend)as totalspend
 from cte1
 where cum_spend>=1000000)
 
 select*
 from cte2
 where totalspend=1;

 
-- 4- write a query to find city which had lowest percentage spend for gold card type

with cte1 as(select city,card_type,sum(amount) as gold_cardspend
from credit_card_transactions
where card_type="gold"
group by city,card_type),
cte2 as(select sum(amount) as totalspend
from credit_card_transactions),
cte3 as(select cte1.*,
round(gold_cardspend/totalspend*100,4) as percentage
from cte1
inner join cte2 
on 1=1),
cte4 as(select*,
dense_rank()over(order by percentage asc) as rn
from cte3)
select*
from cte4
where rn=1;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte1 as (select city,exp_type, sum(amount) as totalspend
from credit_card_transactions
group by city,exp_type),

Cte2 as(select*,
dense_rank()over(partition by city order by totalspend desc) as h_e_t,
dense_rank()over(partition by city order by totalspend asc) as l_e_t
from cte1)

select city,
min(case when l_e_t=1 then exp_type end) as lowest_expensive,
max(case when h_e_t=1 then exp_type end) as highest_expensive
from cte2
group by city;



-- 6- write a query to find percentage contribution of spends by females for each expense type

with cte1 as(select exp_type,sum(amount) as f_spends
from credit_card_transactions
where gender="F"
group by exp_type),

cte2 as (select exp_type, sum(amount) as total_fspends
from credit_card_transactions
group by exp_type)

 select cte1.*,
 round(f_spends/total_fspends*100,2) as percentage
 from cte1
 inner join cte2
 on cte1.exp_type=cte2.exp_type;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

WITH cte1 as(
	SELECT card_type, exp_type, YEAR(transaction_date) yt, 
    MONTH(transaction_date) mt, SUM(amount) as total_spend
	FROM credit_card_transactions
	GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)),
 cte2 as(SELECT *, 
    LAG(total_spend,1) OVER(PARTITION BY card_type, exp_type ORDER BY yt,mt) as prev_mont_spend
	FROM cte1)
SELECT *, (total_spend-prev_mont_spend) as mom_growth
FROM cte2
WHERE prev_mont_spend IS NOT NULL AND yt=2014 AND mt=1
ORDER BY mom_growth DESC
LIMIT 1;



-- 8- during weekends which city has highest total spend to total no of transcations ratio


with cte1 as(SELECT city , SUM(amount)*1.0/COUNT(1) as ratio
FROM credit_card_transactions
WHERE DAYNAME(transaction_date) in ('Saturday','Sunday')
GROUP BY city),
cte2 as (select*,
dense_rank()over(order by ratio desc)as high_ratio
from cte1)
select*
from cte2 
where high_ratio=1;


-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city


WITH cte as(SELECT *,
    ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date, transaction_id) as rn
	FROM credit_card_transactions)
SELECT city, TIMESTAMPDIFF(DAY, MIN(transaction_date), MAX(transaction_date)) as datediff1
FROM cte
WHERE rn=1 or rn=500
GROUP BY city
HAVING COUNT(1)=2
ORDER BY datediff1
LIMIT 1;