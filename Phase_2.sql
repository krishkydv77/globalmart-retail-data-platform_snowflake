-- Phase 2 — Ingest All 3 File Formats into Raw Tables


-- step 1 = create table
-- step 2= copy into 
-- step 3 = Flattening views
                     -- Flatten =>Array ko rows me todta hai.
                     -- lateral=> Har row ke JSON par operation karta hai.
                    -- value =>Flatten ke baad actual JSON object.
                    -- (input=> raw_col) => kis data ko flatten karna hai


-- CSV
CREATE OR REPLACE TABLE global_mart_db.raw.pos_raw (
    transaction_id      STRING,
    store_id            STRING,
    store_name          STRING,
    store_city          STRING,
    store_region        STRING,
    cashier_id          STRING,
    customer_id         STRING,
    transaction_date    DATE,
    transaction_time    TIME,
    product_sku         STRING,
    product_name        STRING,
    category            STRING,
    subcategory         STRING,
    quantity            int,
    unit_price          float,
    discount_pct        int,
    total_amount        float,
    payment_method      STRING,
    loyalty_points      int,
    load_timestamp TIMESTAMP,
    file_name STRING
);


COPY INTO global_mart_db.raw.pos_raw
FROM
(
    SELECT
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,
        CURRENT_TIMESTAMP(),
        METADATA$FILENAME
    FROM @global_mart_db.integrations.stage_pos/pos
) FILE_FORMAT = global_mart_db.integrations.ff_csv;

select * from global_mart_db.raw.pos_raw;

-- JSON
CREATE OR REPLACE TABLE global_mart_db.raw.iot_events_raw (
    event_id STRING,
    event_type STRING,
    store_id STRING,
    store_name STRING,
    event_ts TIMESTAMP,
    device_id STRING,
    raw_payload VARIANT,
    source_file STRING,
    loaded_at TIMESTAMP
);

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

select * from global_mart_db.raw.iot_events_raw;

-- Parquet
drop table global_mart_db.raw.erp_orders;
create or replace table global_mart_db.raw.erp_orders(col_all variant);
select * from global_mart_db.raw.erp_orders;

create or replace table global_mart_db.raw.erp_order_raw(
 order_id string,
    order_date datetime,
    store_id string,
    supplier_id string,
    store_city string,
    supplier_name string,
    supplier_city string,
    product_sku string,
    category string,
    unit_cost float,
    quantity_ordered int,
    quantity_received int,
    order_status string,
    expected_delivery date,
    actual_delivery date,
    warehouse_id string,
    lead_time_days int,
    is_late string,
    file_load_time timestamp,
    source_file string
);

copy into global_mart_db.raw.erp_order_raw from 
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

select * from global_mart_db.raw.erp_order_raw;






-- step 3 = Flattening views 

SELECT
        event_id,
        event_type,
        store_id,
        store_name,
        event_ts,
        device_id,
        raw_payload:metadata.firmware::STRING  as firmware,
        raw_payload:metadata.battery_pct::INT  as battery_pct,
        raw_payload:metadata.store_floor::INT   as store_floor,
        f.value:sensor::STRING  as sensor_name,
        f.value:value::FLOAT  as sensor_value,
        f.value:unit::STRING   as sensor_unit,
        source_file,
        loaded_at,
        CURRENT_TIMESTAMP()  as processed_ts
    FROM global_mart_db.raw.iot_events_raw,
         LATERAL FLATTEN(input => raw_payload:readings) f;


create or replace view global_mart_db.raw.sensor_iot as
SELECT
        event_id,
        event_type,
        store_id,
        store_name,
        event_ts,
        device_id,
        raw_payload:metadata.firmware::STRING  as firmware,
        raw_payload:metadata.battery_pct::INT  as battery_pct,
        raw_payload:metadata.store_floor::INT   as store_floor,
        f.value:sensor::STRING  as sensor_name,
        f.value:value::FLOAT  as sensor_value,
        f.value:unit::STRING   as sensor_unit,
        source_file,
        loaded_at,
        CURRENT_TIMESTAMP()  as processed_ts
    FROM global_mart_db.raw.iot_events_raw,
         LATERAL FLATTEN(input => raw_payload:readings) f;

select * from global_mart_db.raw.sensor_iot;

-- alrat
SELECT e.EVENT_ID, e.STORE_ID, e.EVENT_TS, a.VALUE:alert_id::VARCHAR AS ALERT_ID, a.VALUE:type::VARCHAR AS ALERT_TYPE, a.VALUE:severity::VARCHAR AS SEVERITY
FROM GLOBAL_MART_DB.RAW.IOT_EVENTS_RAW e, LATERAL FLATTEN(input => e.RAW_PAYLOAD:alerts) a WHERE ARRAY_SIZE(e.RAW_PAYLOAD:alerts) > 0;



