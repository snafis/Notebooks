# Data Processing and Analysis Using Hive

**Introduction**

> **Apache Hive is a high level abstraction on top of MapReduce**
  - Uses an SQL/like language called HiveQL 
  - Generates MapReduce jobs that run on the Hadoop cluster 
  - Originally developed by Facebook for data warehousing 
  - Now an open/source Apache project 

> **Hive runs on the client machine**
  - Turns HiveQL queries into MapReduce jobs 
  - Submits those jobs to the cluster 
  
> **Hive queries operate on tables, just like in an RDBMS**
  - A table is simply an HDFS directory containing one or more files 
  - Hive supports many formats for data storage and retrieval 
  
> **How does Hive know the structure and location of tables?**
  - These are specified when tables are created 
  - This metadata is stored in Hive’s metastore 
  - Contained in an RDBMS such as MySQL 

> **Hive consults the metastore to determine data format and location**
  - The query itself operates on data stored on a filesystem (typically HDFS) 

#### Hive Directory Layout

#### Using the Hive Shell

#### Accessing Hive from the Command Line

```sql 
beeline -u "jdbc:hive2://localhost:10000/default;principal=hive/host@real.com"
scan complete in 3ms
Connecting to jdbc:hive2://localhost:10000/default;principal=hive/host@real.com
Connected to: Apache Hive (version 1.1.0-cdh5.4.2)
Driver: Hive JDBC (version 1.1.0-cdh5.4.2)
Transaction isolation: TRANSACTION_REPEATABLE_READ
Beeline version 1.1.0-cdh5.4.2 by Apache Hive
0: jdbc:hive2://localhost:100>
```


#### Creating a database `CREATE DATABASE ()` `USE ()`

```sql
hive> CREATE DATABASE financials;
hive> CREATE DATABASE IF NOT EXISTS financials;
hive> SHOW DATABASES;
default
financials
hive> DESCRIBE DATABASE financials;
+-----------+----------+-------------------------------------------------------+-------------+-------------+-------------+--+
| db_name   | comment  |                     location                          | owner_name  | owner_type  | parameters  |
+-----------+----------+-------------------------------------------------------+-------------+-------------+-------------+--+
| financials|          | hdfs://nameservice1/user/hive/warehouse/financials.db | hive        | USER        |             |
+-----------+----------+-------------------------------------------------------+-------------+-------------+-------------+--+
```
#### Defining a Hive-Managed Tables `CREATE TABLE (...)`

```sql
CREATE TABLE customers
(cust_id INT, fname STRING, lname STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

DESCRIBE customers;
+-----------+------------+----------+--+
| col_name  | data_type  | comment  |
+-----------+------------+----------+--+
| cust_id   | int        |          |
| fname     | string     |          |
| lname     | string     |          |
+-----------+------------+----------+--+
3 rows selected (0.212 seconds)
```
**Defining an External Table `CREATE TABLE EXTERNAL (...)`

```sql
CREATE EXTERNAL TABLE salaries (
gender string,
age int,
salary double,
zip int
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';
```

#### Defining a Table Location `LOCATION (...)`

```sql
CREATE EXTERNAL TABLE salaries (
gender string,
age int,
salary double,
zip int
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/user/train/salaries/';
```
In the table above, the table data for salaries will be whatever is in the `/user/train/salaries` directory.

IMPORTANT: The sole difference in behavior between external tables and Hive-­‐managed tables is when they are dropped. If you drop a Hive-­‐managed table, then its underlying data is deleted from HDFS. If you drop an external table, then its underlying data remains in HDFS (even if the LOCATION was in /user/hive/warehouse/).

#### Loading Data Into a Hive Table `LOAD DATA (...)`

The data for a Hive table resides in HDFS. To associate data with a table, use the `LOAD DATA` command. 
The data does not actually get "loaded" into anything, but the data does get moved:
* For Hive-managed tables, the data is moved into a special sub-folders of `/user/hive/warehouse`.
* For external tables, the data moved to the folder specified by the `LOCATION` clause in the table's definition.


```sql
LOAD DATA (LOCAL) INPATH "/path/to/customer/data" (OVERWRITE) INTO TABLE customers;
```
* Use `LOCAL` qualifier for loading a file local file system.
* Use `OVERWRITE` qualifier to delete any existing data in the table and replace it with the new data. 

```sql
INSERT INTO birthdays SELECT firstName, lastName, birthday FROM customers WHERE birthday IS NOT NULL;
```
#### Performing Queries `SELECT (...)`

As a simple example,

`select * from customers;`
DOES NOT kick in map reduce, while

`select count(*) from customers;`
DOES. 

What is the general principle used to decide when to use map reduce (by hive)?

In general, any sort of aggregation, such as min/max/count is going to require a MapReduce job. This isn't going to explain everything for you, probably.

Hive, in the style of many RDBMS, has an EXPLAIN keyword that will outline how your Hive query gets translated into MapReduce jobs. Try running explain on both your example queries and see what it is trying to do behind the scenes.


#### Hive Partitions `PARTITIONED BY (...)`

```sql
create table employees (id int, name string, salary double)
partitioned by (dept string);
```
/user/hive/warehouse/employees
/dept=hr/
/dept=support/
/dept=engineering/
/dept=training/


#### Hive Bucketing ``

```sql

```

#### Hive Sample Table `TABLESAMPLE (...)`

```sql
INSERT OVERWRITE TABLE my_table_sample 
SELECT * FROM my_table 
TABLESAMPLE (1 PERCENT) t;


INSERT OVERWRITE TABLE my_table_sample 
SELECT * FROM my_table 
TABLESAMPLE (1m ROWS) t;
```
