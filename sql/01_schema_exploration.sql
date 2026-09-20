---For Reporting
select 
    count(distinct user_id),
    date_trunc('month',signup_date) as cohort_month 
from users 
group by date_trunc('month',signup_date) 
order by cohort_month;

select 
    count(distinct user_id),
    date_trunc('month',signup_date) as cohort_month, 
    sum(count(distinct user_id)) over(order by date_trunc('month',signup_date)) as cum_cnt 
from users 
group by date_trunc('month',signup_date) 
order by cohort_month;

---Month + channel breakdown: kept for reference, too granular to trust (cohort sizes too small once split this many ways)
-- with 
--     cte_users as(
--         select user_id, signup_date, signup_channel, date_trunc('month',signup_date) as cohort_month 
--         from users
--     ),
--     cte_orders as(
--         select user_id, date_trunc('month',order_placed_time) as order_month 
--         from orders
--     ),
--     cte_orders_with_period as(
--         select 
--             u.user_id, u.cohort_month, o.order_month, u.signup_channel,
--             EXTRACT(YEAR FROM AGE(o.order_month, u.cohort_month)) * 12 
--             + EXTRACT(MONTH FROM AGE(o.order_month, u.cohort_month)) as period_number 
--         from cte_users u join cte_orders o on u.user_id = o.user_id
--     ),
--     cte_cohort_sizes as(
--         select cohort_month, signup_channel, count(distinct user_id) as cohort_size 
--         from cte_users 
--         group by cohort_month, signup_channel
--     ),
--     cte_retention as(
--         select cohort_month, signup_channel, period_number, count(distinct user_id) as retained_users_count 
--         from cte_orders_with_period 
--         group by cohort_month, signup_channel, period_number
--     )
-- select 
--     s.cohort_month, r.period_number, r.retained_users_count, r.signup_channel, s.cohort_size,
--     (r.retained_users_count::float / s.cohort_size::float) * 100 as retention_pct 
-- from cte_cohort_sizes s 
-- join cte_retention r on s.cohort_month = r.cohort_month and s.signup_channel = r.signup_channel 
-- order by s.cohort_month, s.signup_channel, r.period_number;

---Channel-only breakdown: the real segment comparison (pooled across all months, real sample sizes)
with 
    cte_users as(
        select user_id, signup_date, signup_channel, date_trunc('month',signup_date) as cohort_month 
        from users
    ),
    cte_orders as(
        select user_id, date_trunc('month',order_placed_time) as order_month 
        from orders
    ),
    cte_orders_with_period as(
        select 
            u.user_id, u.cohort_month, o.order_month, u.signup_channel,
            EXTRACT(YEAR FROM AGE(o.order_month, u.cohort_month)) * 12 
            + EXTRACT(MONTH FROM AGE(o.order_month, u.cohort_month)) as period_number 
        from cte_users u join cte_orders o on u.user_id = o.user_id
    ),
    cte_channel_sizes as (
        select signup_channel, count(distinct user_id) as cohort_size
        from cte_users
        group by signup_channel
    ),
    cte_channel_retention as (
        select signup_channel, period_number, count(distinct user_id) as retained_users_count
        from cte_orders_with_period
        group by signup_channel, period_number
    )
select 
    cs.signup_channel, cr.period_number, cr.retained_users_count, cs.cohort_size,
    (cr.retained_users_count::float / cs.cohort_size::float) * 100 as retention_pct
from cte_channel_sizes cs
join cte_channel_retention cr on cs.signup_channel = cr.signup_channel
order by cs.signup_channel, cr.period_number;

---Churn definition
select 
    user_id,
    max(order_placed_time) as last_order_date,
    (select max(order_placed_time) from orders) as most_recent_order_date,
    case 
        when max(order_placed_time) < (select max(order_placed_time) from orders) - interval '1 month' 
        then 'churned'
        else 'active'
    end as churn_status
from orders
group by user_id;

---Cohort-only breakdown: for the heatmap (cohort_month as rows, period_number as columns)
with 
    cte_users as(
        select user_id, signup_date, signup_channel, date_trunc('month',signup_date) as cohort_month 
        from users
    ),
    cte_orders as(
        select user_id, date_trunc('month',order_placed_time) as order_month 
        from orders
    ),
    cte_orders_with_period as(
        select 
            u.user_id, u.cohort_month, o.order_month, u.signup_channel,
            EXTRACT(YEAR FROM AGE(o.order_month, u.cohort_month)) * 12 
            + EXTRACT(MONTH FROM AGE(o.order_month, u.cohort_month)) as period_number 
        from cte_users u join cte_orders o on u.user_id = o.user_id
    ),
    cte_month_sizes as (
        select cohort_month, count(distinct user_id) as cohort_size
        from cte_users
        group by cohort_month
    ),
    cte_month_retention as (
        select cohort_month, period_number, count(distinct user_id) as retained_users_count
        from cte_orders_with_period
        group by cohort_month, period_number
    )
select 
    ms.cohort_month, mr.period_number, mr.retained_users_count, ms.cohort_size,
    (mr.retained_users_count::float / ms.cohort_size::float) * 100 as retention_pct
from cte_month_sizes ms
join cte_month_retention mr on ms.cohort_month = mr.cohort_month
order by ms.cohort_month, mr.period_number;