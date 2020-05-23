# Data Processing and Analysis Using Impala

## Why Impala?

<iframe src="//www.slideshare.net/slideshow/embed_code/key/3mr611kBOFE418" width="425" height="355" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="//www.slideshare.net/insideHPC/impala-overview" title="Cloudera Impala Technical Overview" target="_blank">Cloudera Impala Technical Overview</a> </strong> from <strong><a href="//www.slideshare.net/insideHPC" target="_blank">insideHPC</a></strong> </div>

<br>

## Getting Up and Running With Impala

### Connecting to Impala

Whichever way you install Impala, at the end of the process you start some Impala-related daemons (impalad, catalogd, and statestored) on every data node in the cluster. 
The most convenient and flexible way to access Impala, and the one this tutorial focuses on, is through the interactive `impala-shell` interpreter. In a development environment, before enabling all the industrial-grade security features, all you need to know is the hostname of any of the servers in the cluster where Impala is running. Impala’s query engine is fully decentralized; you can connect to any data node, issue queries, and the work is automatically distributed across the cluster.

```sql
$ ssh impala_user@host007.dev_cluster.example.com
$ impala-shell
[localhost:21000] > show databases;
```
#### Verbose Shell
```sql
$ impala-shell -i localhost -d oreilly
...
[localhost:21000] > create table foo (x int);
Query: create table foo (x int); 1
Returned 0 row(s) in 1.13s 2
[localhost:21000] > select x from foo;
Query: select x from foo;
Returned 0 row(s) in 0.19s
```
#### Quiet Shell
```sql
$ impala-shell -i localhost -d oreilly --quiet
[localhost:21000] > create table bar (s string);
[localhost:21000] > select s from bar;
```
#### In-line Query
```sql
$ impala-shell -B --quiet -q 'show tables in oreilly' | \
  sed -e 's/^/drop table /' | sed -e 's/$/;/' | \
  tee drop_all_tables.sql
drop table bar;
drop table billion_numbers;
drop table billion_numbers_compacted;
...
```
#### Run a Script in Batch Mode
```sql
$ impala-shell -d oreilly -B -f benchmark.sql
...some startup banner messages...
Query: use oreilly
Query: select count(*) from canada_facts
13
Returned 1 row(s) in 0.21s
Query: select count(*) from canada_regions
13
Returned 1 row(s) in 0.19s
Query: select count(*) from usa_cities
289
Returned 1 row(s) in 0.19s
```
**Ref:** [Impala Shell Configuration Options](http://www.cloudera.com/content/cloudera/en/documentation/cloudera-impala/v2-0-x/topics/impala_shell_options.html)

## Impala SQL Language

[Impala SQL Language Reference](http://bit.ly/impala-sql-lang-ref)

#### Creating a Table `CREATE TABLE`
```sql
$ impala-shell -i localhost
[localhost:21000] > create database oreilly;
[localhost:21000] > use oreilly;
[localhost:21000] > create table sample_data
                  > (id bigint, val int, zerofill string, name string,
                  > assertion boolean, city string, state string)
                  > row format delimited fields terminated by ",";
```

#### Describing a Table `DESCRIBE TABLE`
```sql
[localhost:21000] > desc sample_data;
+-----------+---------+---------+
| name      | type    | comment |
+-----------+---------+---------+
| id        | bigint  |         |
| val       | int     |         |
| zerofill  | string  |         |
| name      | string  |         |
| assertion | boolean |         |
| city      | string  |         |
| state     | string  |         |
+-----------+---------+---------+
[localhost:21000] > describe formatted sample_data;
...
| # Detailed Table Information | NULL
| Database:                    | oreilly
| Owner:                       | jrussell
| CreateTime:                  | Fri Jul 18 16:25:06 PDT 2014
| LastAccessTime:              | UNKNOWN
| Protect Mode:                | None
| Retention:                   | 0
| Location:                    | hdfs://a1730.abcde.example.com:8020 1
|                              | /user/impala/warehouse/oreilly.db/
|                              | sample_data
| Table Type:                  | MANAGED_TABLE
...
```
#### Adding Data to the Table `REFRESH TABLE` `INVALIDATE METADATA`
```sql
[localhost:21000] > !hdfs dfs -put billion_rows.csv '/user/impala/warehouse/oreilly.db/sample_data';
[localhost:21000] > refresh sample_data;
[localhost:21000] > select count(*) from sample_data;
+------------+
| count(*)   |
+------------+
| 1000000000 |
+------------+
Returned 1 row(s) in 45.31s
```

#### Show the Physical Characteristics of the Table `SHOW TABLE STATS`
```sql
[localhost:21000] > show table stats sample_data;
+-------+--------+---------+--------------+--------+
| #Rows | #Files | Size    | Bytes Cached | Format |
+-------+--------+---------+--------------+--------+
| -1    | 1      | 56.72GB | NOT CACHED   | TEXT   | 1
+-------+--------+---------+--------------+--------+
Returned 1 row(s) in 0.01s
```
#### Normalise a Table `CREATE VIEW`
```sql
[localhost:21000] > describe formatted usa_cities;
...
| Location: | hdfs://a1730.abcde.example.com:8020/user/impala/warehouse
|           | /oreilly.db/usa_cities
...
[localhost:21000] > !hdfs dfs -put usa_cities.csv '/user/impala/warehouse/oreilly.db/usa_cities';
[localhost:21000] > refresh usa_cities;
[localhost:21000] > select count(*) from usa_cities;
+----------+
| count(*) |
+----------+
| 289      |
+----------+
[localhost:21000] > show table stats usa_cities;
+-------+--------+--------+--------------+--------+
| #Rows | #Files | Size   | Bytes Cached | Format |
+-------+--------+--------+--------------+--------+
| -1    | 1      | 6.44KB | NOT CACHED   | TEXT   |
+-------+--------+--------+--------------+--------+
Returned 1 row(s) in 0.01s
[localhost:21000] > select * from usa_cities limit 5;
+----+--------------+--------------+
| id | city         | state        |
+----+--------------+--------------+
| 1  | New York     | New York     |
| 2  | Los Angeles  | California   |
| 3  | Chicago      | Illinois     |
| 4  | Houston      | Texas        |
| 5  | Philadelphia | Pennsylvania |
+----+--------------+--------------+
[localhost:21000] > create view normalized_view as
                  > select one.id, one.val, one.zerofill, one.name,
                  >   one.assertion, two.id as location_id
                  > from sample_data one join usa_cities two 1
                  > on (one.city = two.city and one.state = two.state);

[localhost:21000] > select one.id, one.location_id,
                  >   two.id, two.city, two.state 2
                  > from normalized_view one join usa_cities two
                  > on (one.location_id = two.id)
                  > limit 5;
+----------+-------------+-----+-----------+------------+
| id       | location_id | id  | city      | state      |
+----------+-------------+-----+-----------+------------+
| 15840253 | 216         | 216 | Denton    | Texas      |
| 15840254 | 110         | 110 | Fontana   | California |
| 15840255 | 250         | 250 | Gresham   | Oregon     |
| 15840256 | 200         | 200 | Waco      | Texas      |
| 15840257 | 165         | 165 | Escondido | California |
+----------+-------------+-----+-----------+------------+
Returned 5 row(s) in 0.42s

[localhost:21000] > select id, city, state from sample_data 3
                  > where id in (15840253, 15840254, 15840255, 15840256, 15840257);
+----------+-----------+------------+
| id       | city      | state      |
+----------+-----------+------------+
| 15840253 | Denton    | Texas      |
| 15840254 | Fontana   | California |
| 15840255 | Gresham   | Oregon     |
| 15840256 | Waco      | Texas      |
| 15840257 | Escondido | California |
+----------+-----------+------------+
Returned 5 row(s) in 5.27s
[localhost:21000] > create table normalized_text
                  > row format delimited fields terminated by ","
                  > as select * from normalized_view;
+----------------------------+
| summary                    |
+----------------------------+
| Inserted 1000000000 row(s) |
+----------------------------+
Returned 1 row(s) in 422.06s

[localhost:21000] > select * from normalized_text limit 5;
+-----------+-------+----------+------------------+-----------+-------------+
| id        | val   | zerofill | name             | assertion | location_id |
+-----------+-------+----------+------------------+-----------+-------------+
| 921623839 | 95546 | 001301   | Pwwwwwbbe        | false     | 217         |
| 921623840 | 38224 | 018053   | Clldddddddll     | true      | 127         |
| 921623841 | 73153 | 032797   | Csssijjjjjj      | true      | 124         |
| 921623842 | 35567 | 094193   | Uhhhhhrrrrrrvvv  | false     | 115         |
| 921623843 | 4694  | 051840   | Uccccqqqqqbbbbbb | true      | 138         |
+-----------+-------+----------+------------------+-----------+-------------+

[localhost:21000] > show table stats normalized_text;
+-------+--------+---------+--------------+--------+
| #Rows | #Files | Size    | Bytes Cached | Format |
+-------+--------+---------+--------------+--------+
| -1    | 4      | 42.22GB | NOT CACHED   | TEXT   | 1
+-------+--------+---------+--------------+--------+
```
#### Converting to Parquet Format `STORED AS PARQUET`
```sql
[localhost:21000] > create table normalized_parquet stored as parquet 1
                  > as select * from normalized_text;
+----------------------------+
| summary                    |
+----------------------------+
| Inserted 1000000000 row(s) |
+----------------------------+
Returned 1 row(s) in 183.63s
[localhost:21000] > select count(*) from normalized_parquet;
+------------+
| count(*)   |
+------------+
| 1000000000 |
+------------+
Returned 1 row(s) in 2.63s
[localhost:21000] > show table stats normalized_parquet;
+-------+--------+---------+--------------+---------+
| #Rows | #Files | Size    | Bytes Cached | Format  |
+-------+--------+---------+--------------+---------+
| -1    | 64     | 23.34GB | NOT CACHED   | PARQUET | 2
+-------+--------+---------+--------------+---------+
Returned 1 row(s) in 0.01s
localhost:21000] > create table denormalized_parquet stored as parquet as
                 > select * from sample_data;
+----------------------------+
| summary                    |
+----------------------------+
| Inserted 1000000000 row(s) |
+----------------------------+
Returned 1 row(s) in 225.69s
[localhost:21000] > show table stats denormalized_parquet;
+-------+--------+---------+--------------+---------+
| #Rows | #Files | Size    | Bytes Cached | Format  |
+-------+--------+---------+--------------+---------+
| -1    | 64     | 24.04GB | NOT CACHED   | PARQUET | 1
+-------+--------+---------+--------------+---------+
Returned 1 row(s) in 0.01s
```
#### Making a Partitioned Table
```sql
[localhost:21000] > desc normalized_parquet;
+-------------+----------+---------+
| name        | type     | comment |
+-------------+----------+---------+
| id          | bigint   |         |
| val         | int      |         |
| zerofill    | string   |         |
| name        | string   |         |
| assertion   | boolean  |         |
| location_id | smallint |         |
+-------------+----------+---------+
Returned 6 row(s) in 0.01s

[localhost:21000] > create view partitioned_normalized_view as
                  > select id, val, zerofill, name, assertion, location_id,
                  > substr(name,1,1) as initial 1
                  > from normalized_parquet;
Returned 0 row(s) in 2.89s

[localhost:21000] > select id, name, initial
                  > from partitioned_normalized_view limit 5;
+-----------+----------------------+---------+
| id        | name                 | initial |
+-----------+----------------------+---------+
| 663027574 | Ckkvvvvvvvmmmmmmm    | C       |
| 663027575 | Fkkkkkkkwwwwwwwyyyyy | F       |
| 663027576 | Orrrrrrrfmmmmm       | O       |
| 663027577 | Peeevvvvvvvvvv       | P       |
| 663027578 | Dmmmmhhhs            | D       |
+-----------+----------------------+---------+
Returned 5 row(s) in 4.65s
[localhost:21000] > create table partitioned_normalized_parquet
                  > (id bigint, val int, zerofill string, name string,
                  > assertion boolean, location_id smallint)
                  > partitioned by (initial string) stored as parquet; 1
Returned 0 row(s) in 1.81s
[localhost:21000] > insert into partitioned_normalized_parquet partition(initial)
                  > select * from partitioned_normalized_view; 2
Inserted 1000000000 rows in 619.28s
[localhost:21000] > show table stats partitioned_normalized_parquet;
+---------+-------+--------+----------+--------------+---------+
| initial | #Rows | #Files | Size     | Bytes Cached | Format  |
+---------+-------+--------+----------+--------------+---------+
| A       | -1    | 3      | 871.79MB | NOT CACHED   | PARQUET | 1
| B       | -1    | 3      | 871.72MB | NOT CACHED   | PARQUET |
| C       | -1    | 3      | 871.40MB | NOT CACHED   | PARQUET |
| D       | -1    | 3      | 871.64MB | NOT CACHED   | PARQUET |
| E       | -1    | 3      | 871.54MB | NOT CACHED   | PARQUET |
| F       | -1    | 3      | 871.11MB | NOT CACHED   | PARQUET |
| G       | -1    | 3      | 871.29MB | NOT CACHED   | PARQUET |
| H       | -1    | 3      | 871.42MB | NOT CACHED   | PARQUET |
| K       | -1    | 3      | 871.42MB | NOT CACHED   | PARQUET |
| L       | -1    | 3      | 871.31MB | NOT CACHED   | PARQUET |
| M       | -1    | 3      | 871.38MB | NOT CACHED   | PARQUET |
| N       | -1    | 3      | 871.25MB | NOT CACHED   | PARQUET |
| O       | -1    | 3      | 871.14MB | NOT CACHED   | PARQUET |
| P       | -1    | 3      | 871.44MB | NOT CACHED   | PARQUET |
| Q       | -1    | 3      | 871.55MB | NOT CACHED   | PARQUET |
| R       | -1    | 3      | 871.30MB | NOT CACHED   | PARQUET |
| S       | -1    | 3      | 871.50MB | NOT CACHED   | PARQUET |
| T       | -1    | 3      | 871.65MB | NOT CACHED   | PARQUET |
| Y       | -1    | 3      | 871.57MB | NOT CACHED   | PARQUET |
| Z       | -1    | 3      | 871.54MB | NOT CACHED   | PARQUET |
| NULL    | -1    | 1      | 147.30MB | NOT CACHED   | PARQUET | 2
| I       | -1    | 3      | 871.44MB | NOT CACHED   | PARQUET |
| J       | -1    | 3      | 871.32MB | NOT CACHED   | PARQUET |
| U       | -1    | 3      | 871.36MB | NOT CACHED   | PARQUET |
| V       | -1    | 3      | 871.39MB | NOT CACHED   | PARQUET |
| W       | -1    | 3      | 871.79MB | NOT CACHED   | PARQUET |
| X       | -1    | 3      | 871.95MB | NOT CACHED   | PARQUET |
| Total   | -1    | 79     | 22.27GB  | 0B           |         |
+---------+-------+--------+----------+--------------+---------+
Returned 28 row(s) in 0.04s
```
#### Performing Joins `COMPUTE STATS`, `EXPLAIN`

```sql
[localhost:21000] > create table stats_demo like sample_data;
[localhost:21000] > show table stats stats_demo;
+-------+--------+------+--------------+--------+
| #Rows | #Files | Size | Bytes Cached | Format |
+-------+--------+------+--------------+--------+
| -1    | 0      | 0B   | NOT CACHED   | TEXT   |
+-------+--------+------+--------------+--------+
[localhost:21000] > show column stats stats_demo;
+-----------+---------+------------------+--------+----------+----------+
| Column    | Type    | #Distinct Values | #Nulls | Max Size | Avg Size |
+-----------+---------+------------------+--------+----------+----------+
| id        | BIGINT  | -1               | -1     | 8        | 8        | 1
| val       | INT     | -1               | -1     | 4        | 4        |
| zerofill  | STRING  | -1               | -1     | -1       | -1       | 2
| name      | STRING  | -1               | -1     | -1       | -1       |
| assertion | BOOLEAN | -1               | -1     | 1        | 1        |
| city      | STRING  | -1               | -1     | -1       | -1       |
| state     | STRING  | -1               | -1     | -1       | -1       |
+-----------+---------+------------------+--------+----------+----------+
[localhost:21000] > insert into stats_demo select * from sample_data limit 1000000;
[localhost:21000] > compute stats stats_demo;
+-----------------------------------------+
| summary                                 |
+-----------------------------------------+
| Updated 1 partition(s) and 7 column(s). |
+-----------------------------------------+
[localhost:21000] > show table stats stats_demo;
+---------+--------+---------+--------------+--------+
| #Rows   | #Files | Size    | Bytes Cached | Format |
+---------+--------+---------+--------------+--------+
| 1000000 | 1      | 57.33MB | NOT CACHED   | TEXT   |
+---------+--------+---------+--------------+--------+
[localhost:21000] > show column stats stats_demo;
+-----------+---------+------------------+--------+----------+-------------+
| Column    | Type    | #Distinct Vals | #Nulls | Max Size | Avg Size      |
+-----------+---------+----------------+--------+----------+---------------+
| id        | BIGINT  | 1023244        | -1     | 8        | 8             | 1
| val       | INT     | 139017         | -1     | 4        | 4             |
| zerofill  | STRING  | 101761         | -1     | 6        | 6             |
| name      | STRING  | 1005653        | -1     | 22       | 13.0006999969 | 2 3
| assertion | BOOLEAN | 2              | -1     | 1        | 1             |
| city      | STRING  | 282            | -1     | 16       | 8.78960037231 | 4
| state     | STRING  | 46             | -1     | 20       | 8.40079975128 | 4
+-----------+---------+----------------+--------+----------+---------------+
[localhost:21000] > explain select count(*) from sample_data join stats_demo
                  > using (id) where substr(sample_data.name,1,1) = 'G';
+--------------------------------------------------------------------+
| Explain String                                                     |
+--------------------------------------------------------------------+
| Estimated Per-Host Requirements: Memory=5.75GB VCores=2            |
| WARNING: The following tables are missing relevant table           |
|          and/or column statistics.                                 | 1
| oreilly.sample_data                                                |
|                                                                    |
| 06:AGGREGATE [MERGE FINALIZE]                                      |
| |  output: sum(count(*))                                           |
| |                                                                  |
| 05:EXCHANGE [UNPARTITIONED]                                        |
| |                                                                  |
| 03:AGGREGATE                                                       |
| |  output: count(*)                                                |
| |                                                                  |
| 02:HASH JOIN [INNER JOIN, BROADCAST]                               |
| |  hash predicates: oreilly.stats_demo.id = oreilly.sample_data.id |
| |                                                                  |
| |--04:EXCHANGE [BROADCAST]                                         |
| |  |                                                               |
| |  00:SCAN HDFS [oreilly.sample_data]                              | 2
| |     partitions=1/1 size=56.72GB                                  |
| |     predicates: substr(sample_data.name, 1, 1) = 'G'             |
| |                                                                  |
| 01:SCAN HDFS [oreilly.stats_demo]                                  | 3
|    partitions=1/1 size=57.33MB                                     |
+--------------------------------------------------------------------+
[localhost:21000] > compute stats sample_data; 1
+-----------------------------------------+
| summary                                 |
+-----------------------------------------+
| Updated 1 partition(s) and 7 column(s). |
+-----------------------------------------+
[localhost:21000] > show table stats sample_data;
+------------+--------+---------+--------------+--------+
| #Rows      | #Files | Size    | Bytes Cached | Format |
+------------+--------+---------+--------------+--------+
| 1000000000 | 1      | 56.72GB | NOT CACHED   | TEXT   | 2
+------------+--------+---------+--------------+--------+
[localhost:21000] > show column stats sample_data;
+-----------+---------+----------------+--------+----------+---------------+
| Column    | Type    | #Distinct Vals | #Nulls | Max Size | Avg Size      |
+-----------+---------+----------------+--------+----------+---------------+
| id        | BIGINT  | 183861280      | 0      | 8        | 8             |
| val       | INT     | 139017         | 0      | 4        | 4             |
| zerofill  | STRING  | 101761         | 0      | 6        | 6             |
| name      | STRING  | 145636240      | 0      | 22       | 13.0002002716 | 3
| assertion | BOOLEAN | 2              | 0      | 1        | 1             |
| city      | STRING  | 282            | 0      | 16       | 8.78890037536 |
| state     | STRING  | 46             | 0      | 20       | 8.40139961242 |
+-----------+---------+----------------+--------+----------+---------------+
[localhost:21000] > explain select count(*) from sample_data join stats_demo
                  > using (id) where substr(sample_data.name,1,1) = 'G';
+--------------------------------------------------------------------+
| Explain String                                                     |
+--------------------------------------------------------------------+
| Estimated Per-Host Requirements: Memory=3.77GB VCores=2            |
|                                                                    |
| 06:AGGREGATE [MERGE FINALIZE]                                      |
| |  output: sum(count(*))                                           |
| |                                                                  |
| 05:EXCHANGE [UNPARTITIONED]                                        |
| |                                                                  |
| 03:AGGREGATE                                                       |
| |  output: count(*)                                                |
| |                                                                  |
| 02:HASH JOIN [INNER JOIN, BROADCAST]                               |
| |  hash predicates: oreilly.sample_data.id = oreilly.stats_demo.id |
| |                                                                  |
| |--04:EXCHANGE [BROADCAST]                                         |
| |  |                                                               |
| |  01:SCAN HDFS [oreilly.stats_demo]                               | 1
| |     partitions=1/1 size=57.33MB                                  |
| |                                                                  |
| 00:SCAN HDFS [oreilly.sample_data]                                 | 2
|    partitions=1/1 size=56.72GB                                     |
|    predicates: substr(sample_data.name, 1, 1) = 'G'                | 3
+--------------------------------------------------------------------+
```
