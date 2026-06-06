-- Phase 3 — Automate and Protect
    -- 1= snowpipe =>notification create  
    -- 2 = transient or temporary table create
    -- 3 = stream(append only/normal stream)
    -- 4 = time travel

-- json pipe

create or replace pipe global_mart_db.integrations.pipe_iot_event
auto_ingest  = true 
as
COPY INTO global_mart_db.raw.iot_events_raw
FROM
(
    SELECT
        $1:event_id::STRING,
        $1:event_type::STRING,
        $1:store_id::STRING,
        $1:store_name::STRING,
        $1:timestamp::TIMESTAMP,
        $1:device_id::STRING,
        $1 as raw_payload,
        METADATA$FILENAME,
        CURRENT_TIMESTAMP()
    FROM @global_mart_db.integrations.stage_iot/iot
) FILE_FORMAT = global_mart_db.integrations.ff_json;

desc pipe global_mart_db.integrations.pipe_iot_event;

select * from global_mart_db.raw.iot_events_raw; 

-- csv 

create or replace pipe global_mart_db.integrations.pipe_pos_raw
auto_ingest  = true 
as
COPY INTO global_mart_db.raw.pos_raw
FROM
(
    SELECT
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,
        CURRENT_TIMESTAMP(),
        METADATA$FILENAME
    FROM @global_mart_db.integrations.stage_pos/pos
) FILE_FORMAT = global_mart_db.integrations.ff_csv;

desc pipe global_mart_db.integrations.pipe_pos_raw;

select * from global_mart_db.raw.pos_raw;

-- PARQUET
create or replace pip global_mart_db.integrations.pipe_erp_order_raw
auto_ingest=true
as
copy into global_mart_db.raw.erp_order_raw
from 
(
select
        $1:order_id::STRING,
        $1:order_date::DATETIME,
        $1:store_id::STRING,
        $1:supplier_id::STRING,  
        $1:store_city::STRING,
        $1:supplier_name::STRING,
        $1:supplier_city::STRING,
        $1:product_sku::STRING,
        $1:category::STRING,
        $1:unit_cost::FLOAT,
        $1:quantity_ordered::INT,
        $1:quantity_received::INT,
        $1:order_status::STRING,
        $1:expected_delivery::DATE,
        $1:actual_delivery::DATE,
        $1:warehouse_id::STRING,
        $1:lead_time_days::INT,
        $1:is_late::STRING,
        CURRENT_TIMESTAMP(),
        METADATA$FILENAME
    from @global_mart_db.integrations.stage_erp/erp
)  file_format=global_mart_db.integrations.ff_parquet;



-- ======================bronze layer======================
 -- 3 = stream(append only/normal stream) 
create or replace stream global_mart_db.raw.stream_iot_event
on table global_mart_db.raw.iot_events_raw
append_only = True;

select * from global_mart_db.raw.stream_iot_event;


create or replace stream global_mart_db.raw.stream_pos_raw
on table global_mart_db.raw.pos_raw
append_only = True;

select * from global_mart_db.raw.stream_pos_raw;

create or replace stream global_mart_db.raw.stream_erp_order_raw
on table global_mart_db.raw.erp_order_raw
append_only = True;

select * from global_mart_db.raw.stream_erp_order_raw;




