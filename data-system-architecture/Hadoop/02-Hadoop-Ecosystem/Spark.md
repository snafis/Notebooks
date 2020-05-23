# What is Spark?

Spark is a general purpose cluster computing framework that provides efficient in-memory computations for large data sets by distributing computation across multiple computers. If you're familiar with Hadoop, then you know that any distributed computing framework needs to solve two problems: how to distribute data and how to distribute computation. Hadoop uses HDFS to solve the distributed data problem and MapReduce as the programming paradigm that provides effective distributed computation. Similarly, Spark has a functional programming API in multiple languages that provides more operators than map and reduce, and does this via a distributed data framework called resilient distributed datasets or RDDs.

RDDs are essentially a programming abstraction that represents a read-only collection of objects that are partitioned across machines. RDDs can be rebuilt from a lineage (and are therefore fault tolerant), are accessed via parallel operations, can be read from and written to distributed storages like HDFS or S3, and most importantly, can be cached in the memory of worker nodes for immediate reuse. Because RDDs can be cached in memory, Spark is extremely effective at iterative applications, where the data is being reused throughout the course of an algorithm. Most machine learning and optimization algorithms are iterative, making Spark an extremely effective tool for data science. Additionally, because Spark is so fast, it can be accessed in an interactive fashion via a command line prompt similar to the Python REPL.

The Spark library itself contains a lot of the application elements that have found their way into most Big Data applications including support for SQL-like querying of big data, machine learning and graph algorithms, and even support for live streaming data.

The core components are:

**Spark Core**: Contains the basic functionality of Spark; in particular the APIs that define RDDs and the operations and actions that can be undertaken upon them. The rest of Spark's libraries are built on top of the RDD and Spark Core.
Spark SQL: Provides APIs for interacting with Spark via the Apache Hive variant of SQL called Hive Query Language (HiveQL). Every database table is represented as an RDD and Spark SQL queries are transformed into Spark operations. For those that are familiar with Hive and HiveQL, Spark can act as a drop-in replacement.

**Spark Streaming**: Enables the processing and manipulation of live streams of data in real time. Many streaming data libraries (such as Apache Storm) exist for handling real-time data. Spark Streaming enables programs to leverage this data similar to how you would interact with a normal RDD as data is flowing in.

**MLlib**: A library of common machine learning algorithms implemented as Spark operations on RDDs. This library contains scalable learning algorithms like classifications, regressions, etc. that require iterative operations across large data sets. The Mahout library, formerly the Big Data machine learning library of choice, will move to Spark for its implementations in the future.

**GraphX**: A collection of algorithms and tools for manipulating graphs and performing parallel graph operations and computations. GraphX extends the RDD API to include operations for manipulating graphs, creating subgraphs, or accessing all vertices in a path.
Because these components meet many Big Data requirements as well as the algorithmic and computational requirements of many data science tasks, Spark has been growing rapidly in popularity. Not only that, but Spark provides APIs in Scala, Java, and Python; meeting the needs for many different groups and allowing more data scientists to easily adopt Spark as their Big Data solution.


# Programming Spark

Programming Spark applications is similar to other data flow languages that had previously been implemented on Hadoop. Code is written in a driver program which is lazily evaluated, and upon an action, the driver code is distributed across the cluster to be executed by workers on their partitions of the RDD. Results are then sent back to the driver for aggregation or compilation. Essentially the driver program creates one or more RDDs, applies operations to transform the RDD, then invokes some action on the transformed RDD.

These steps are outlined as follows:

* Define one or more RDDs either through accessing data stored on disk (HDFS, Cassandra, HBase, Local Disk), parallelizing some collection in memory, transforming an existing RDD, or by caching or saving.
* Invoke operations on the RDD by passing closures (functions) to each element of the RDD. Spark offers over 80 high level operators beyond Map and Reduce.
* Use the resulting RDDs with actions (e.g. count, collect, save, etc.). Actions kick off the computing on the cluster.

![image](http://1.bp.blogspot.com/-jjuVIANEf9Y/Ur3vtjcIdgI/AAAAAAAABC0/-Ou9nANPeTs/s1600/p1.png)

When Spark runs a closure on a worker, any variables used in the closure are copied to that node, but are maintained within the local scope of that closure. Spark provides two types of shared variables that can be interacted with by all workers in a restricted fashion. Broadcast variables are distributed to all workers, but are read-only. Broadcast variables can be used as lookup tables or stopword lists. Accumulators are variables that workers can "add" to using associative operations and are typically used as counters.

Spark applications are essentially the manipulation of RDDs through transformations and actions. Future posts will go into this in greater detail, but this understanding should be enough to execute the example programs below.

# Spark Execution

Essentially, Spark applications are run as independent sets of processes, coordinated by a `SparkContext` in a driver program. The context will connect to some cluster manager (e.g. YARN) which allocates system resources. Each worker in the cluster is managed by an executor, which is in turn managed by the SparkContext. The executor manages computation as well as storage and caching on each machine.

![image](https://docs.sigmoidanalytics.com/images/0/01/S6.png)

What is important to note is that application code is sent from the driver to the executors, and the executors specify the context and the various tasks to be run. The executors communicate back and forth with the driver for data sharing or for interaction. Drivers are key participants in Spark jobs, and therefore, they should be on the same network as the cluster. This is different from Hadoop code, where you might submit a job from anywhere to the JobTracker, which then handles the execution on the cluster.

