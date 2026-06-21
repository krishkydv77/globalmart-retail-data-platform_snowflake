--Gold layer

-- 1. Daily Sales Fact
truncate table global_mart_db.marts.daily_sales_fact;
create or replace table global_mart_db.marts.daily_sales_fact(
 report_date timestamp,
 store_id string,
 store_city string,
 store_name string,
 category string,
 total_revenue_generated int,
 Store_region string,
 total_units_sold int,
 total_transaction_done int,
 average_cart_size int,
 total_unique_customer int,
 date_update date);

 insert into global_mart_db.marts.daily_sales_fact
  select 
  transaction_date as report_date,
  store_id,
  store_city ,
  store_name,
  category ,
  sum(Total_amount) as  total_revenue_generated, --  Revenue: (Units Sold × Price) -  Discounts
  Store_region,
  sum(quantity) as total_units_sold ,
  count(transaction_id) as total_transaction_done,
  avg(Total_amount) as average_cart_size,
  count(distinct customer_id) as total_unique_customer,
  current_date as date_update
  from  global_mart_db.staging.stg_csv_transaction
  group by transaction_date ,Store_region,store_city ,store_name,store_id , category order by transaction_date;

select * from global_mart_db.marts.daily_sales_fact;
 select count(distinct total_revenue_generated) from  global_mart_db.marts.daily_sales_fact ;
select count( total_revenue_generated) from  global_mart_db.marts.daily_sales_fact ;
-- 2. gross margin fact

  select * from   global_mart_db.marts.GROSS_MARGIN_FACT;

create or replace table global_mart_db.marts.GROSS_MARGIN_FACT as  

WITH csv_cte AS (
    SELECT store_id, store_name,  category,
        SUM(quantity) AS number_of_units_sold,
        SUM(line_total) AS line_total,
        COUNT(DISTINCT customer_id) AS unique_customer_id
    FROM global_mart_db.staging.stg_csv_transaction
    GROUP BY store_id, store_name, category
),
parquet_cte AS (
    SELECT store_id, category,
    AVG(total_cost / ifnull(quantity_received, 0)) AS per_item_cost
    FROM global_mart_db.staging.stg_erp_parquet
    GROUP BY store_id, category
)

SELECT
    p.store_id,  c.store_name, p.category,
    c.line_total AS total_revenue_generated, 
    (c.number_of_units_sold * p.per_item_cost) AS total_cost_generated,
    c.line_total - (c.number_of_units_sold * p.per_item_cost) AS gross_profit_margin,
    ( ( c.line_total -  (c.number_of_units_sold * p.per_item_cost) ) / c.line_total) * 100 AS gross_margin_percentage,
    c.number_of_units_sold,
    c.unique_customer_id
FROM csv_cte c
JOIN parquet_cte p
    ON LOWER(c.store_id) = LOWER(p.store_id)
    AND LOWER(c.category) = LOWER(p.category)
ORDER BY c.store_id,p.category;










-- 3. sensor_iot_fact
select * from   global_mart_db.marts.sensor_pivot;
create or replace table  global_mart_db.marts.sensor_pivot
as
SELECT *
FROM (
    SELECT date(event_ts) as event_date,
        store_id,
        store_name,

        sensor_name,
        sensor_value
    FROM global_mart_db.staging.stg_json_sensor
)
PIVOT (
    AVG(sensor_value)
    FOR sensor_name IN (
        'footfall' AS avg_footfall,
        'weight_kg' AS avg_weight,
        'temp_c' AS avg_temp,
        'humidity_pct' as avg_humidity,
        'power_kw' as avg_power
    )
);




select *  from GLOBAL_MART_DB.marts.sensor_pivot;



    