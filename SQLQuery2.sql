select * from users
select * from logins

1. Which users did not log in during the past 5 months?

with cte as
(select user_id, month(max(login_timestamp)) as last_login,
month(getdate()) as present_date
from logins
group by user_id)

select s.user_name from users s join cte c
on s.user_id = c.user_id
where (c.present_date-c.last_login >= 5);
--------------------------------------------------------------------------------------------------
2. How many users and sessions were there in each quarter, ordered from newest to oldest?
-- Return: first day of the quarter, user_cnt, session_cnt.

select DATEPART(quarter, LOGIN_TIMESTAMP) as quarter_number,COUNT(*) as session_cnt,
COUNT(distinct USER_ID) as user_cnt
,DATETRUNC(quarter,MIN(LOGIN_TIMESTAMP)) as first_quarter_date
from logins
group by DATEPART(quarter, LOGIN_TIMESTAMP)	
---------------------------------------------------------------------------------------------------
3. Which users logged in during January 2024 but did not log in during November 2023?

select distinct user_id from logins 
where LOGIN_TIMESTAMP between '2024-01-01' and '2024-01-31' AND user_id NOT IN 
(select user_id from logins where LOGIN_TIMESTAMP between '2023-11-01' and '2023-11-30')
-----------------------------------------------------------------------------------------------------
4. What is the percentage change in sessions from the last quarter?
 
with cte as 
(select COUNT(*) as session_cnt,
COUNT(distinct USER_ID) as user_cnt
,DATETRUNC(quarter,MIN(LOGIN_TIMESTAMP)) as first_quarter_date
from logins
group by DATEPART(quarter, LOGIN_TIMESTAMP)	
)
select *, LAG(session_cnt) over(order by first_quarter_date) as prev_session_cnt 
,(session_cnt - (LAG(session_cnt) over(order by first_quarter_date)))*100.0/(LAG(session_cnt) over(order by first_quarter_date)) as percentage_change
from cte 
---------------------------------------------------------------------------------------------------------
5. Which user had the highest session score each day?
-- Return: Date, user_id , score

with cte as(
select user_id, CAST(LOGIN_TIMESTAMP as date) as login_date
, SUM(session_score) as score
from logins
group by user_id, CAST(LOGIN_TIMESTAMP as date)
--order by CAST(LOGIN_TIMESTAMP as date),score
)
select * from (
select * , ROW_NUMBER() over(partition by login_date order by score desc)as rn 
from cte) a
where rn=1

------------------------------------------------------------------------------------------------------------------------
6. Which users have had a session every single day since their first login?

select * from logins
with cte as (
select user_id, CAST(LOGIN_TIMESTAMP as date) as date
from logins 
group by user_id, CAST(LOGIN_TIMESTAMP as date))

select user_id, min(CAST(LOGIN_TIMESTAMP as date)) as first_login 
,DATEDIFF(day, min(CAST(LOGIN_TIMESTAMP as date)),GETDATE())-38 as no_of_login_days_required
,COUNT(distinct CAST(LOGIN_TIMESTAMP as date)) as no_of_login_days
from logins
group by user_id
having (DATEDIFF(day, min(CAST(LOGIN_TIMESTAMP as date)),GETDATE())-38)=(COUNT(distinct CAST(LOGIN_TIMESTAMP as date)))
order by user_id

---------------------------------------------------------------------------------------------------------------
7. On what dates were there no logins at all?

select * from logins
select * from calendar_dim

--solution-1
select cal_date
from calendar_dim c 
INNER JOIN (select cast(min(LOGIN_TIMESTAMP) as date) as first_date, cast(max(LOGIN_TIMESTAMP) as date) as last_date
from logins) a on c.cal_date between first_date and last_date
where cal_date not in
(select distinct cast(LOGIN_TIMESTAMP as date) from logins)

--solution-2
with cte as ( 
select cast(min(LOGIN_TIMESTAMP) as date) as first_date, cast(max(LOGIN_TIMESTAMP) as date) as last_date
from logins
union all
select DATEADD(day,1,first_date) as first_date, last_date from cte
where first_date<last_date
)
select * from cte
where first_date not in 
(select distinct cast(LOGIN_TIMESTAMP AS DATE) from logins)
option(maxrecursion 500)