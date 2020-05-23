# Data Processing and Analysis Using Spark

#### Pre-Flight Checks


#### Spark Deconstructed

#### A Brief History

#### Simple Spark Apps

Here is the infamous wordcount problem in Spark

```scala
val f = sc.textFile("war_and_peace.txt")
f: org.apache.spark.rdd.RDD[String] = war_and_peace.txt MappedRDD[1] at textFile at <console>:12

val wc = f.flatMap(l => l.split(" ")).map(word => (word, 1)).reduceByKey(_+_)

wc.toDebugString
res0: String = 
(2) ShuffledRDD[4] at reduceByKey at <console>:14
 +-(2) MappedRDD[3] at map at <console>:14
    |  FlatMappedRDD[2] at flatMap at <console>:14
    |  war_and_peace.txt MappedRDD[1] at textFile at <console>:12
    |  war_and_peace.txt HadoopRDD[0] at textFile at <console>:12

wc.saveAsTextFile("wc_out")

```

```scala

// Define a date format for parsing later on
val format = new java.text.SimpleDateFormat("yyyy-MM-dd")

// Define schema 
case class Register (d: java.util.Date, uuid: String, cust_id: String, lat: Float, lng: Float)
case class Click (d: java.util.Date, uuid: String, landing_page: Int)

// Define transformations on both input files
val reg = sc.textFile("reg.tsv").map(_.split("\t")).map(
  r => (r(1), Register(format.parse(r(0)), r(1), r(2), r(3).toFloat, r(4).toFloat))) 
val clk = sc.textFile("clk.tsv").map(_.split("\t")).map(
  c => (c(1), Click(format.parse(c(0)), c(1), c(2).trim.toInt)))

// Join the two datasets
reg.join(clk)

reg.join(clk).toDebugString
res7: String = 
(2) FlatMappedValuesRDD[27] at join at <console>:23
 |  MappedValuesRDD[26] at join at <console>:23
 |  CoGroupedRDD[25] at join at <console>:23
 +-(2) MappedRDD[6] at map at <console>:16
 |  |  MappedRDD[5] at map at <console>:16
 |  |  reg.tsv MappedRDD[4] at textFile at <console>:16
 |  |  reg.tsv HadoopRDD[3] at textFile at <console>:16
 +-(2) MappedRDD[17] at map at <console>:16
    |  MappedRDD[16] at map at <console>:16
    |  clk.tsv MappedRDD[15] at textFile at <console>:16
    |  clk.tsv HadoopRDD[14] at textFile at <console>:16
    

//action the transformations
reg.join(clk).collect()
reg.join(clk).saveAsTextFile("join_out")
```

#### Spark API

#### Spark SQL

```scala
val sqlContext = new org.apache.spark.sql.SQLContext(sc)
import sqlContext._
// Define the schema using a case class.
case class Person(name: String, age: Int)
// Create an RDD of Person objects and register it as a table.
val people = sc.textFile("examples/src/main/resources/
people.txt").map(_.split(",")).map(p => Person(p(0), p(1).trim.toInt))
people.registerAsTable("people")
// SQL statements can be run by using the sql methods provided by sqlContext.
val teenagers = sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")
// The results of SQL queries are SchemaRDDs and support all the
// normal RDD operations.
// The columns of a row in the result can be accessed by ordinal.
teenagers.map(t => "Name: " + t(0)).collect().foreach(println)

```

#### Spark Streaming

```scala

// http://spark.apache.org/docs/latest/streaming-programming-guide.html
import org.apache.spark.streaming._
import org.apache.spark.streaming.StreamingContext._
// create a StreamingContext with a SparkConf configuration
val ssc = new StreamingContext(sparkConf, Seconds(10))
// create a DStream that will connect to serverIP:serverPort
val lines = ssc.socketTextStream(serverIP, serverPort)
// split each line into words
val words = lines.flatMap(_.split(" "))
// count each word in each batch
val pairs = words.map(word => (word, 1))
val wordCounts = pairs.reduceByKey(_ + _)
// print a few of the counts to the console
wordCounts.print()
ssc.start() // start the computation
ssc.awaitTermination() // wait for the computation to terminate

```


#### GraphX and MLlib

#### Putting It All Together

Twitter Streaming Language 

#### SDLC for Spark
