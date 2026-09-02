create table user_activity(
event_id int primary key,
user_id int,
event_type varchar(59),
event_date time,
product_id int,
amount numeric(8,2),
traffic_source varchar(39)
)

select * from user_activity
limit 10


-- Question: What is the number of unique users at each stage of the sales funnel,
-- from page view to add to cart, checkout, payment information, and final purchase?

with sales_funnel as (
select 
count(distinct case when event_type='page_view' then user_id end) as stage_1_views,
count(distinct case when event_type='add_to_cart' then user_id end) as stage_2_carts,
count(distinct case when event_type='checkout_start' then user_id end) as stage_3_checkout,
count(distinct case when event_type='payment_info' then user_id end) as stage_4_payment,
count(distinct case when event_type='purchase' then user_id end) as stage_5_purchase
from user_activity

)

select * from sales_funnel


-- Question: What is the conversion rate between each stage of the sales funnel,
-- and what percentage of visitors ultimately complete a purchase?

with funnel_conversion as (
select 
count(distinct case when event_type='page_view' then user_id end) as stage_1_views,
count(distinct case when event_type='add_to_cart' then user_id end) as stage_2_carts,
count(distinct case when event_type='checkout_start' then user_id end) as stage_3_checkout,
count(distinct case when event_type='payment_info' then user_id end) as stage_4_payment,
count(distinct case when event_type='purchase' then user_id end) as stage_5_purchase
from user_activity

)

select 
stage_1_views,
stage_2_carts, round(stage_2_carts*100.0/stage_1_views,0) as view_to_cart_rate,


stage_3_checkout,
round(stage_3_checkout*100/stage_2_carts,0) as cart_to_checkout_rate,

stage_4_payment,
round(stage_4_payment*100/stage_3_checkout) as checkout_to_payment,


round(stage_5_purchase*100/stage_1_views,0) as overall_conversion_rate


from sales_funnel



-- Question: How does the sales funnel perform across different traffic sources,
-- and which traffic sources generate the highest number of purchases and conversion rates?

with source_performance as (
select 
traffic_source,
count(distinct case when event_type='page_view' then user_id end) as views,
count(distinct case when event_type='add_to_cart' then user_id end) as carts,

count(distinct case when event_type='purchase' then user_id end) as purchase
from user_activity
group by traffic_source
)

select 
traffic_source,views,carts,purchase,
round(carts*100/views,0) as views_to_carts_rate,
round(purchase*100/carts,0) as views_to_purchase_rate,
round(purchase*100/views,0) as purchase_conversion_rate
from sales_funnel
order by purchase desc


-- Question: How much time do converted users take to move from page view to cart,
-- from cart to purchase, and from the initial view to the final purchase?

WITH user_journey AS (
    SELECT 
        user_id,

        MIN(CASE 
            WHEN event_type = 'page_view' 
            THEN event_date 
        END) AS view_time,

        MIN(CASE 
            WHEN event_type = 'add_to_cart' 
            THEN event_date 
        END) AS cart_time,

        MIN(CASE 
            WHEN event_type = 'purchase' 
            THEN event_date 
        END) AS purchase_time

    FROM user_activity

    GROUP BY user_id

    HAVING 
        AND MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)

SELECT 
    COUNT(*) AS converted_users,

    AVG(EXTRACT(EPOCH FROM (cart_time - view_time)) / 60)
        AS avg_view_to_cart_minutes,

    AVG(EXTRACT(EPOCH FROM (purchase_time - cart_time)) / 60)
        AS avg_cart_to_purchase_minutes,

    AVG(EXTRACT(EPOCH FROM (purchase_time - view_time)) / 60)
        AS avg_total_journey_minutes

FROM user_journey
WHERE view_time <= cart_time
  AND cart_time <= purchase_time;



-- Question: What is the overall revenue performance of the sales funnel,
-- including total visitors, purchasing users, total revenue, average order value,
-- and average revenue generated per visitor?

with funnel_revenue as (
select
count(distinct case when event_type='page_view' then user_id end) as total_visitors,
count(distinct case when event_type='purchase' then user_id end) as total_purchasing_orders,
sum( case when event_type='purchase' then amount end ) as total_revenue
from user_activity
)
select 
total_visitors,total_purchasing_orders, total_revenue,
round((total_revenue/total_purchasing_orders),0) as avg_order_value,
round((total_revenue/total_visitors),0) as revenue_visitor_value
from funnel_revenue