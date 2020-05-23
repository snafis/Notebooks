## Creating a Hadoop Pseudo-Distributed Environment

Hadoop developers usually test their scripts and code on a **pseudo-distributed environment** (also known as a single node setup), which is a virtual machine that runs all of the Hadoop daemons simultaneously on a single machine. This allows you to quickly write scripts and test them on limited data sets without having to connect to a remote cluster or pay the expense of EC2. If you're learning Hadoop, you'll probably also want to set up a pseudo-distributed environment to facilitate your understanding of the various Hadoop daemons.

These instructions will help you install a Hadoop pseudo-distributed environment on Mac OS X.


#### Directory Structure

The Linux operating system depends upon a hierarchical directory structure to function. At the root, many directories that you've heard of have specific purposes:

* `/etc` is used to store configuration files
* `/home` is used to store user specific files
* `/bin` and `/sbin` include programs that are vital for the OS
* `/usr/sbin` are for programs that are not vital but are system wide
* `/usr/local` is for locally installed programs
* `/var` is used for program data including caches and logs

You can read more about these directories in [this Stack Exchange post](http://serverfault.com/questions/96416/should-i-install-linux-applications-in-var-or-opt).

A good choice to move Hadoop to is the /opt and /srv directories.

`/opt` contains non-packaged programs, usually source. A lot of developers stick their code there for deployments.

`/srv` directory stands for services. Hadoop, HBase, Hive and others run as services on your machine, so this seems like a great place to put things, and it's a standard location that's easy to get to. So let's stick everything there!

#### Install Workflow

For the most part, installing services on Hadoop (e.g. Hive, HBase, or others) will consist of the following in the environment we have set up:

* Download the release tarball of the service
* Unpack the release to /srv/ and creating a symlink from the release to a simple name
* Configure environment variables with the new paths
* Configure the service to run in pseudo-distributed mode

#### Hadoop

```
~ > hadoop version
Hadoop 1.2.0
Subversion https://svn.apache.org/repos/asf/hadoop/common/branches/branch-1.2 -r 1479473
Compiled by hortonfo on Mon May  6 06:59:37 UTC 2013
From source with checksum 2e0dac51ede113c1f2ca8e7d82fb3405
This command was run using /usr/local/hadoop-1.2.0/hadoop-core-1.2.0.jar
```

Configure NameNode on port 10001 in `core-site.html`:

``` xml
/usr/local/hadoop/conf > cat core-site.xml 
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://localhost:10001</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/Users/TheOracle/Developments/Hadoop/hdfs/</value>
    </property>
</configuration>
```
Configure JobTracker on port 10002 in `mapred-site.xml`:

```xml
/usr/local/hadoop/conf > cat mapred-site.xml 
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapred.job.tracker</name>
        <value>localhost:10002</value>
    </property>
    <property>
        <name>mapred.tasktracker.map.tasks.maximum</name>
        <value>1</value>
    </property>
    <property>
        <name>mapred.tasktracker.reduce.tasks.maximum</name>
        <value>1</value>
    </property> 
    <property>
        <name>mapred.max.split.size</name>
        <value>1000</value>
    </property>
</configuration>
```

#### Hive

Find the Hive release you wish to download from the Apache Hive downloads page. 

At the time of this writing, Hive release 0.14.0 is current. 

Once you have selected a mirror, download the apache-hive-0.14.0-bin.tar.gz file to your downloads directory. 

Then issue the following commands in the terminal to unpack it:

```bash

~$ tar -xzf apache-hive-0.14.0-bin.tgz
~$ sudo mv apache-hive-0.14.0-bin /usr/local
~$ sudo chown -R hadoop:hadoop /usr/local/apache-hive-0.14.0-bin
~$ sudo ln -s /usr/local/apache-hive-0.14.0-bin /usr/local/hive
```
Edit your `~/.bashrc_local` with these environment variables by adding the following to the bottom of the file:


```bash
# HIVE
export set HIVE_INSTALL=/usr/local/hive
export set PATH=$PATH:$HIVE_INSTALL/bin
```

No other configuration for Hive is required, although you can find other configuration details in `HIVE_HOME/conf` including the Hive environment shell file and the Hive site configuration XML.

To test the setup, lauch Hive shell by typing `hive` (make sure Hadoop services are running) :

```sql

/usr/local > hive
Logging initialized using configuration in jar:file:/usr/local/hive-0.11.0/lib/hive-common-0.11.0.jar!/hive-log4j.properties
Hive history file=/tmp/TheOracle/hive_job_log_TheOracle_2844@Shifaths-MBP.lan_201508090351_128841676.txt

-- Check configuration parameters, in particular `mapred.job.tracker=localhost:10002`
hive> set -v
```

Create a test database and verify `metastore db` in the filesystem:

```sql
hive> show tables;
OK
Time taken: 0.045 seconds
hive> create database test;
OK
Time taken: 0.291 seconds
hive> use test;
OK
Time taken: 0.024 seconds
hive> CREATE TABLE book(word STRING)
    > ROW FORMAT DELIMITED
    > FIELDS TERMINATED BY ' '
    > LINES TERMINATED BY '\n'
    > ;
OK
Time taken: 0.704 seconds
hive> desc book;
OK
word                	string              	None                
Time taken: 0.475 seconds, Fetched: 1 row(s)
hive> desc extended book;
OK
word                	string              	None                
	 	 
Detailed Table Information	Table(tableName:book, dbName:test, owner:TheOracle, createTime:1439089169, lastAccessTime:0, retention:0, sd:StorageDescriptor(cols:[FieldSchema(name:word, type:string, comment:null)], location:hdfs://localhost:10001/user/hive/warehouse/test.db/book, inputFormat:org.apache.hadoop.mapred.TextInputFormat, outputFormat:org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat, compressed:false, numBuckets:-1, serdeInfo:SerDeInfo(name:null, serializationLib:org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe, parameters:{serialization.format= , field.delim= , line.delim=	 
}), bucketCols:[], sortCols:[], parameters:{}, skewedInfo:SkewedInfo(skewedColNames:[], skewedColValues:[], skewedColValueLocationMaps:{}), storedAsSubDirectories:false), partitionKeys:[], parameters:{numPartitions=0, numFiles=1, transient_lastDdlTime=1439091100, numRows=0, totalSize=3291648, rawDataSize=0}, viewOriginalText:null, viewExpandedText:null, tableType:MANAGED_TABLE)		 
Time taken: 0.117 seconds, Fetched: 4 row(s)

```

Now load data into the table:

```sql
hive> LOAD DATA INPATH 'hdfs:/data/war_and_peace.txt' INTO TABLE book;
Loading data to table test.book
Table test.book stats: [num_partitions: 0, num_files: 1, num_rows: 0, total_size: 3291648, raw_data_size: 0]
OK
Time taken: 0.998 seconds
hive> SELECT * FROM book LIMIT 10;
OK
The

This
no
under
eBook


Title:

Time taken: 0.459 seconds, Fetched: 10 row(s)
```

Run a MapReduce job to get the total row count:

```sql
hive> SELECT COUNT(*) FROM book; 
Total MapReduce jobs = 1
Launching Job 1 out of 1
Number of reduce tasks determined at compile time: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapred.reduce.tasks=<number>
Starting Job = job_201508090356_0003, Tracking URL = http://localhost:50030/jobdetails.jsp?jobid=job_201508090356_0003
Kill Command = /usr/local/hadoop-1.2.0/libexec/../bin/hadoop job  -kill job_201508090356_0003
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 1
2015-08-09 04:38:34,825 Stage-1 map = 0%,  reduce = 0%
2015-08-09 04:38:38,888 Stage-1 map = 100%,  reduce = 0%
2015-08-09 04:38:48,052 Stage-1 map = 100%,  reduce = 100%
Ended Job = job_201508090356_0003
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 1   HDFS Read: 3291875 HDFS Write: 6 SUCCESS
Total MapReduce CPU Time Spent: 0 msec
OK
65007
Time taken: 22.957 seconds, Fetched: 1 row(s)
```

Now lets count the number of distinct words:

```sql
hive> SELECT COUNT(DISTINCT word) FROM book; 
Total MapReduce jobs = 1
Launching Job 1 out of 1
Number of reduce tasks determined at compile time: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapred.reduce.tasks=<number>
Starting Job = job_201508090356_0004, Tracking URL = http://localhost:50030/jobdetails.jsp?jobid=job_201508090356_0004
Kill Command = /usr/local/hadoop-1.2.0/libexec/../bin/hadoop job  -kill job_201508090356_0004
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 1
2015-08-09 04:39:33,297 Stage-1 map = 0%,  reduce = 0%
2015-08-09 04:39:38,336 Stage-1 map = 100%,  reduce = 0%
2015-08-09 04:39:46,436 Stage-1 map = 100%,  reduce = 33%
2015-08-09 04:39:48,458 Stage-1 map = 100%,  reduce = 100%
Ended Job = job_201508090356_0004
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 1   HDFS Read: 3291875 HDFS Write: 6 SUCCESS
Total MapReduce CPU Time Spent: 0 msec
OK
12500
Time taken: 26.312 seconds, Fetched: 1 row(s)
hive>
```

Now time for a bit for involved query:

```sql
hive> select lower(word), count(*) as count  
    > from book                              
    > where lower(substring(word, 1, 1)) = 'w'
    > group by word                           
    > having count > 50                       
    > sort by count desc;                     
Total MapReduce jobs = 2
Launching Job 1 out of 2
Number of reduce tasks not specified. Estimated from input data size: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapred.reduce.tasks=<number>
Starting Job = job_201508090356_0005, Tracking URL = http://localhost:50030/jobdetails.jsp?jobid=job_201508090356_0005
Kill Command = /usr/local/hadoop-1.2.0/libexec/../bin/hadoop job  -kill job_201508090356_0005
Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 1
2015-08-09 04:53:44,206 Stage-1 map = 0%,  reduce = 0%
2015-08-09 04:53:51,271 Stage-1 map = 100%,  reduce = 0%
2015-08-09 04:54:00,374 Stage-1 map = 100%,  reduce = 33%
2015-08-09 04:54:01,386 Stage-1 map = 100%,  reduce = 100%
Ended Job = job_201508090356_0005
Launching Job 2 out of 2
Number of reduce tasks not specified. Estimated from input data size: 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapred.reduce.tasks=<number>
Starting Job = job_201508090356_0006, Tracking URL = http://localhost:50030/jobdetails.jsp?jobid=job_201508090356_0006
Kill Command = /usr/local/hadoop-1.2.0/libexec/../bin/hadoop job  -kill job_201508090356_0006
Hadoop job information for Stage-2: number of mappers: 1; number of reducers: 1
2015-08-09 04:54:10,113 Stage-2 map = 0%,  reduce = 0%
2015-08-09 04:54:14,142 Stage-2 map = 100%,  reduce = 0%
2015-08-09 04:54:23,270 Stage-2 map = 100%,  reduce = 33%
2015-08-09 04:54:24,282 Stage-2 map = 100%,  reduce = 100%
Ended Job = job_201508090356_0006
MapReduce Jobs Launched: 
Job 0: Map: 1  Reduce: 1   HDFS Read: 3291875 HDFS Write: 336 SUCCESS
Job 1: Map: 1  Reduce: 1   HDFS Read: 794 HDFS Write: 89 SUCCESS
Total MapReduce CPU Time Spent: 0 msec
OK
with	368
was	366
which	171
when	166
were	152
would	110
who	99
what	93
without	76
when	74
Time taken: 52.587 seconds, Fetched: 10 row(s)
hive> 
```

Setting up the Metastore DB in MySQL

Follow the MySQL [installation guide]().

Update the `hive-site.xml` configuration file as follows:

```xml
<property>
 <name>javax.jdo.option.ConnectionPassword</name>
 <value>password</value>
 <description>password to use against metastore database</description>
 </property>
 <property>
 <name>javax.jdo.option.ConnectionURL</name>
 <value>jdbc:mysql://localhost/metastore</value>
 <description>JDBC connect string for a JDBC metastore</description>
 </property>
 <property>
 <name>javax.jdo.option.ConnectionDriverName</name>
 <value>com.mysql.jdbc.Driver</value>
 <description>Driver class name for a JDBC metastore</description>
 </property>
 <property>
 <name>javax.jdo.option.ConnectionUserName</name>
 <value>username</value>
 <description>Username to use against metastore database</description>
 </property>
```

Other useful Hive settings:

```xml
<property>
 <name>hive.cli.print.current.db</name>
 <value>true</value>
 <description>Whether to include the current database in the Hive prompt.</description>
 </property>
 <property>
 <name>hive.stats.jdbcdriver</name>
 <value>com.mysql.jdbc.Driver</value>
 <description>JDBC driver for the database that stores temporary Hive statistics.</description>
 </property>
 <property>
 <name>hive.stats.dbconnectionstring</name>
 <value>jdbc:mysql://localhost/tempstatsstore</value>
 <description>The default connection string for the database that stores temporary Hive statistics.</description>
 </property>
 <property>
 <name>hive.cli.print.header</name>
 <value>true</value>
 <description>Whether to print the names of the columns in query output.</description>
 </property>
```

Start Hive Metastore

```
nohup hive --service metastore>$HIVE_INSTALL/hive_metastore.out 2>$HIVE_INSTALL/hive_metastore.log & 
```


Check that MySQL database is running and the character set for metastore database is set to latin1
`alter database hive character set latin1;`

Open Hive command line shell.

```
hive
create database test;
use test;
create table user_info(userid int, user_name string);
load data local inpath "/usr/local/hive/examples/files/kv1.txt" overwrite into table user_info;
select * from user_info limit 10;
select count(distinct userid) from user_info;
```


#### Zookeeper

#### Sqoop

#### Spark

Find the Spark release you wish to download from the [Apache Spark downloads page](https://spark.apache.org/downloads.html). The Spark release at the time of this writing is 1.1.0. You should choose the package type "Pre-built for Hadoop 2.4" and the download type should be "Direct Download". Then unpack it as follows:

```bash
~$ tar -xzf spark-1.1.0-bin-hadoop2.4.tgz
~$ sudo mv spark-1.1.0-bin-hadoop2.4.tgz /usr/local
~$ sudo chown -R hadoop:hadoop /usr/local/spark-1.1.0-bin-hadoop2.4
~$ sudo ln -s /usr/local/spark-1.1.0-bin-hadoop2.4 /usr/local/spark
```

Edit your `~/.bashrc_local` with the following environment variables at the bottom of the file:

```bash
# Configure Spark environment
export SPARK_INSTALL=/usr/local/spark
export PATH=$SPARK_INSTALL/bin:$PATH
```

After you source your `.bashrc_local` or restart your terminal, you should be able to run a `pyspark` interpreter locally. You can now use `pyspark` and `spark-submit` commands to run Spark jobs.

Execute the `pyspark` command, and you should see a result as follows:

```
/usr/local/spark > pyspark 
Python 2.7.9 |Anaconda 2.2.0 (x86_64)| (default, Dec 15 2014, 10:37:34) 
[GCC 4.2.1 (Apple Inc. build 5577)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
Anaconda is brought to you by Continuum Analytics.
Please check out: http://continuum.io/thanks and https://binstar.org
Spark assembly has been built with Hive, including Datanucleus jars on classpath
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=128m; support was removed in 8.0
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
15/08/09 05:26:21 INFO SecurityManager: Changing view acls to: TheOracle,
15/08/09 05:26:21 INFO SecurityManager: Changing modify acls to: TheOracle,
15/08/09 05:26:21 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users with view permissions: Set(TheOracle, ); users with modify permissions: Set(TheOracle, )
15/08/09 05:26:22 INFO Slf4jLogger: Slf4jLogger started
15/08/09 05:26:23 INFO Remoting: Starting remoting
15/08/09 05:26:23 INFO Remoting: Remoting started; listening on addresses :[akka.tcp://sparkDriver@shifaths-mbp.lan:51366]
15/08/09 05:26:23 INFO Remoting: Remoting now listens on addresses: [akka.tcp://sparkDriver@shifaths-mbp.lan:51366]
15/08/09 05:26:23 INFO Utils: Successfully started service 'sparkDriver' on port 51366.
15/08/09 05:26:24 INFO SparkEnv: Registering MapOutputTracker
15/08/09 05:26:24 INFO SparkEnv: Registering BlockManagerMaster
15/08/09 05:26:24 INFO DiskBlockManager: Created local directory at /var/folders/r_/9tbmwmnj2p171knpdx_czh0c0000gn/T/spark-local-20150809052624-20f2
15/08/09 05:26:25 INFO Utils: Successfully started service 'Connection manager for block manager' on port 51367.
15/08/09 05:26:25 INFO ConnectionManager: Bound socket to port 51367 with id = ConnectionManagerId(shifaths-mbp.lan,51367)
15/08/09 05:26:25 INFO MemoryStore: MemoryStore started with capacity 265.1 MB
15/08/09 05:26:25 INFO BlockManagerMaster: Trying to register BlockManager
15/08/09 05:26:25 INFO BlockManagerMasterActor: Registering block manager shifaths-mbp.lan:51367 with 265.1 MB RAM
15/08/09 05:26:25 INFO BlockManagerMaster: Registered BlockManager
15/08/09 05:26:25 INFO HttpFileServer: HTTP File server directory is /var/folders/r_/9tbmwmnj2p171knpdx_czh0c0000gn/T/spark-def17761-9c70-4409-991b-fc6d1ebd9888
15/08/09 05:26:25 INFO HttpServer: Starting HTTP Server
15/08/09 05:26:26 INFO Utils: Successfully started service 'HTTP file server' on port 51368.
15/08/09 05:26:27 INFO Utils: Successfully started service 'SparkUI' on port 4040.
15/08/09 05:26:27 INFO SparkUI: Started SparkUI at http://shifaths-mbp.lan:4040
15/08/09 05:26:28 INFO AkkaUtils: Connecting to HeartbeatReceiver: akka.tcp://sparkDriver@shifaths-mbp.lan:51366/user/HeartbeatReceiver
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 1.1.0
      /_/

Using Python version 2.7.9 (default, Dec 15 2014 10:37:34)
SparkContext available as sc.
>>> 

```

Checkout the SparkUI on `http://localhost:4040`.

The execution of Spark (and PySpark) can be extremely verbose, with many `INFO` log messages printed out to the screen. This is particularly annoying during development, as Python stack traces or the output of print statements can be lost. In order to reduce the verbosity of Spark, you can configure the log4j settings in `$SPARK_INSTALL/conf`. First, create a copy of the `$SPARK_INSTALL/conf/log4j.properties.template` file, removing the ".template" extension.

```bash
~$ cp $SPARK_INSTALL/conf/log4j.properties.template $SPARK_INSTALL/conf/log4j.properties
```

Edit the newly copied file and replace INFO with WARN at every line in the code(`:%s/INFO/WARN`). Your `log4j.properties` file should look similar to:

```java
# Set everything to be logged to the console
log4j.rootCategory=WARN, console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

# Settings to quiet third party logs that are too verbose
log4j.logger.org.eclipse.jetty=WARN
log4j.logger.org.eclipse.jetty.util.component.AbstractLifeCycle=ERROR
log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper=WARN
log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter=WARN
```

Now when you run PySpark you should get much simpler output messages!

Run the wordcount example as below:
```scala
>>> sc = SparkContext(appName="PythonWordCount")
>>> lines = sc.textFile("hdfs://localhost:10001/data/shakespeare.txt")
>>> from operator import add
>>> counts = lines.flatMap(lambda x: x.split(' ')).map(lambda x: (x, 1)).reduceByKey(add)
>>> output = counts.collect()
>>> for (word, count) in output:
>>>     print("%s: %i" % (word, count))
>>> counts.saveAsTextFile("hdfs://localhost:10001/data/wc")
>>> sc.stop()
```
If you check the HDFS UI on `http://localhost:50075`, you should see a directory called "wc". Each part file represents a partition of the final RDD that was computed by various processes on your computer and saved to HGFS. If you inspect each of the part files, you should see tuples of word count pairs.

Note that none of the keys are sorted as they would be in Hadoop (due to a necessary shuffle and sort phase between the Map and Reduce tasks). However, you are guaranteed that each key appears only once across all part files as you used the reduceByKey operator on the counts RDD. If you want, you could use the sort operator to ensure that all the keys are sorted before writing them to disk.

We can easily turn this interactive code into a Spark application by creating the `wordcount.py` script as follows and running it using `spark-submit`:

```python
from __future__ import print_function

import sys
from operator import add
from pyspark import SparkContext

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: wordcount <file>", file=sys.stderr)
        exit(-1)
    sc = SparkContext(appName="PythonWordCount")
    lines = sc.textFile(sys.argv[1], 1)
    counts = lines.flatMap(lambda x: x.split(' ')) \
                  .map(lambda x: (x, 1)) \
                  .reduceByKey(add)
    output = counts.collect()
    for (word, count) in output:
        print("%s: %i" % (word, count))

    sc.stop()
```


```bash

