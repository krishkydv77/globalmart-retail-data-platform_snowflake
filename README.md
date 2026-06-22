# GlobalMart Retail End-to-End Data Platform

##  Project Overview
GlobalMart is a retail chain with 10 stores across Turkey (Istanbul, Izmir, Ankara, and Antalya). Before this project, the company's data lived in three separate, disconnected systems: POS (Sales data in CSV), ERP (Inventory/Cost data in Parquet), and IoT Sensors (Store environment data in JSON). 

This project builds an end-to-end cloud data platform on **Snowflake** using the **Medallion Architecture (Bronze -> Silver -> Gold)**. It connects all three data sources, processes **225,160 rows** of data, tracks changes automatically, and connects directly to **Power BI** for executive dashboards.

---

## System Architecture & Data Flow



[ AWS S3 Buckets (CSV / Parquet / JSON) ]

│

▼ (Storage Integration + SQS Notifications + Snowpipe)
[ Bronze Layer (raw schema) ] ───► (Data Protection via Time Travel)

│

▼ (Streams & Automated Tasks / Data Flattening)
[ Silver Layer (staging schema) ]

│

▼ (Business Logic & Aggregated Fact Tables)
[ Gold Layer (marts schema) ]

│

▼ (Direct Connection)
[ Power BI Executive Dashboard ]


---

##  Snowflake Features Used
This Proof of Concept (POC) implements **14 major Snowflake features**:
* **Infrastructure:** Storage Integrations, External Stages, File Formats.
* **Data Ingestion:** Bulk Loading (`COPY INTO`) and Real-time Auto-Ingestion (`Snowpipe`).
* **Semi-Structured Data:** `VARIANT` column type and `LATERAL FLATTEN` to parse nested JSON arrays.
* **Automation (CDC):** Standard Streams, `APPEND_ONLY` Streams, Scheduled Tasks, and Root/Child Task DAGs.
* **Data Protection:** Time Travel (using Offset, Timestamp, and Statement), `UNDROP Table`, and Fail-Safe.
* **Performance:** Zero-Copy Cloning and Materialized Views.

---

##  Database Layer Design (Medallion Architecture)
The project uses **5 different schemas** to organize data cleanly:

1. **`integrations` (Infrastructure):** Stores secure S3 connections, file formats, and external stages.
2. **`raw` (Bronze Layer):** Keeps exact, unmodified copies of the source files for history and recovery.
3. **`staging` (Silver Layer):** Cleans, transforms, removes duplicates, and standardizes data using automated pipelines.
4. **`marts` (Gold Layer):** Houses clean, business-ready aggregate tables and fact tables for BI reports.
5. **`utilities` (Helper Layer):** Holds temporary tables and quick staging buffers used during nightly runs.

---

## ☁️ AWS S3 Cloud Integration & Security Setup
To bring data safely from AWS S3 into Snowflake, the following security infrastructure was configured:
* **IAM Roles & Policies:** Created a secure IAM Role in AWS with strict permissions to read only specific S3 buckets.
* **Storage Integration:** Set up a `STORAGE INTEGRATION` object in Snowflake. This creates a secure cloud-to-cloud trust connection using AWS ARNs, meaning no raw AWS passwords or access keys are hardcoded.
* **External Stages:** Mapped three distinct stages (`stg_pos`, `stg_erp`, `stg_iot`) pointing to separate S3 folder paths.
* **SQS Notification Integration:** Automated data ingestion by linking AWS S3 Event Notifications to a Snowflake SQS queue. Whenever a new file lands in S3, it alerts Snowpipe to load it instantly.

---

##  Automated Ingestion & Transformation Pipelines

### 1. POS System Pipeline (CSV Format - 120,000 Rows)
* Raw data is loaded into the Bronze layer. An `APPEND_ONLY` stream tracks new rows coming in.
* A scheduled Root Task runs every 15 minutes, checks if the stream has new data, and automatically moves it to the Silver staging table (`stg_pos_transactions`) while cleaning it.

### 2. ERP System Pipeline (Parquet Format - 45,000 Rows)
* Columnar Parquet data is extracted using field names and type-casted into rows.
* A Standard Stream tracks order status updates (e.g., Shipped, Delivered). A nightly task uses a `MERGE` query to update records smoothly into the staging layer.

### 3. IoT Sensor Pipeline (JSON Format - 60,000 Rows)
* Initial files are loaded manually, while final files use **Snowpipe** for auto-ingestion into a `VARIANT` column.
* Because JSON data is nested, a `LATERAL FLATTEN` view is used. This automatically explodes 1 raw event into 2 flat rows (separating Temperature, Power, and Humidity data) so it can be queried normally with SQL.

---

##  Backup, Recovery, & Cost Optimization Demos

* **Time Travel Recovery:** Simulated a bad query where an analyst mistakenly wiped out discount data. Used `BEFORE(STATEMENT => 'query_id')` to restore the correct values instantly.
* **Undrop Table:** Accidentally dropped the inventory table and restored it immediately using a single `UNDROP TABLE` command.
* **Transient Tables for Savings:** Configured daily temporary staging tables as `TRANSIENT`. This removes Snowflake's Fail-Safe storage fees, saving cloud costs on tables that are rebuilt every night.
* **Zero-Copy Cloning:** Created a live development database (`globalmart_dev_db`) from production in under a second. This gives developers a full test environment for free without duplicating any storage cost.

---

## Power BI Dashboard Executive Insights
The final Power BI dashboard connects directly to Snowflake's Gold layer and delivers key business insights:

### 1. Executive KPIs (Top Cards)
* Displays company-wide metrics clearly: **Total Revenue (587.08M)**, **Total Transactions (120.00K)**, **Average Ticket Size (140.97M)**, and **Total Unique Customers (119.95K)**.

### 2. Revenue vs Footfall Analysis (Store Conversion)
* **Visual:** Line and Clustered Column Chart.
* **Insight:** Compares total revenue (bars) against average footfall traffic (line) for each store. This helps managers find conversion risks—for example, if a store has very high customer traffic but low revenue, it flags that people are visiting but leaving without buying things.

### 3. Regional and Operational Metrics
* **Regional Market Share:** A doughnut chart tracking sales by region, showing that the *Marmara* region brings in about 50% of total revenue.
* **Store Operations Analysis:** A combo chart that displays traffic alongside utility costs (Power and Humidity) so managers can track utility wastage in physical stores.

---

##  How to Run this Project
1. **AWS Setup:** Create an S3 bucket, set up an IAM Role, and copy the ARN details.
2. **Snowflake Setup:** Execute the SQL bootstrap script using `ACCOUNTADMIN` to build the infrastructure, integration objects, and medallion layers.
3. **Start Pipelines:** Enable the data streams and tasks by setting their status to `RESUME`.
4. **BI Connection:** Open the Power BI file, type in your Snowflake warehouse details, and refresh the data to see live results.

---
##  Acknowledgments / Guidance
* This project was successfully built and completed under the expert guidance and mentorship of **Tushar Goyal(Sr. Data Engineer)**. 
* Special thanks for providing the architectural roadmap, structural insights, and continuous support throughout the development of this end-to-end data platform.
