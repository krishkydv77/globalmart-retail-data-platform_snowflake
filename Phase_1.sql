-- PHASE 1: Snowflake Setup, Schemas, Warehouses, Stages

-- step=1 Database Creation
-- step=2  Schemas Creation
-- step=3 Warehouses Creation
-- step=4 Storage Integration
-- step=5 File Formats Creation

-- step=6 External Stages Creation


 -- step=1 Database Creation
create database if not exists global_mart_db
comment='Globa Mart retail data platform';
USE DATABASE global_mart_db;


-- step=2  Schemas Creation
create schema if not exists global_mart_db.integrations;  -- phase 1
create schema if not exists global_mart_db.raw;    -- phase 2
create schema if not exists global_mart_db.staging;
-- create schema if not exists global_mart_db.marts;
-- create schema if not exists global_mart_db.utilities;

-- -- step=3 Warehouses Creation
-- create warehouse if not exists gm_ingest_wh 
--     with warehouse_size = 'XSMALL' 
--     auto_suspend = 60 
--     auto_resume = TRUE 
--     initially_suspended = TRUE;

-- create warehouse if not exists gm_transform_wh 
--     with warehouse_size = 'SMALL' 
--     auto_suspend = 60 
--     auto_resume = TRUE 
--     initially_suspended = TRUE;

-- step=4 Storage Integration 
DROP INTEGRATION s3_integration;
create storage integration s3_integration
type=external_stage
storage_provider='s3'
enabled=TRUE
storage_aws_role_arn='arn:aws:iam::58---------------56:role/snowflake_s3_kesn_role'
storage_allowed_locations=('s3://global-mart-pro-tu-2026/');

desc  integration s3_integration;

-- step=5 File Formats Creation 
create or replace file format global_mart_db.integrations.ff_csv
TYPE = 'CSV' 
FIELD_DELIMITER = ',' 
SKIP_HEADER = 1 
FIELD_OPTIONALLY_ENCLOSED_BY = '"' 
NULL_IF = ('NULL', 'null', '');

create or replace file format global_mart_db.integrations.ff_parquet
TYPE = 'PARQUET';

create or replace file format global_mart_db.integrations.ff_json
TYPE = 'JSON' 
STRIP_OUTER_ARRAY = TRUE;

-- step=6 External Stages Creation
-- DROP STAGE IF EXISTS global_mart_db.integrations.stage_pos;
create or replace stage global_mart_db.integrations.stage_pos
url='s3://global-mart-pro-tu-2026/pos/'
storage_integration= s3_integration;

list @global_mart_db.integrations.stage_pos;

create or replace stage global_mart_db.integrations.stage_iot
url='s3://global-mart-pro-tu-2026/Iot/'
storage_integration= s3_integration;

list @global_mart_db.integrations.stage_iot;

create or replace stage global_mart_db.integrations.stage_erp
url='s3://global-mart-pro-tu-2026/erp/'
storage_integration= s3_integration;

list @global_mart_db.integrations.stage_erp;



