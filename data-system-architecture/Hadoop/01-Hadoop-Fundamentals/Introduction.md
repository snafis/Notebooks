<!---
The Case for Apache Hadoop
Author: Shifath Nafis
Date: 4th May, 2015
-->

# The Case for Apache Hadoop

## The current state of affairs

The Data Deluge

We are generating **more data** than ever:
* Financial transactions
* Sensr networks
* Server logs
* Social network
* Emails and Text messages

We are generating **data faster** than ever:
* Ubiquitious computing
* Machine-to-Machine 
* User-generated content

This data has many valuable application: 
* Marketing analysis
* Product recommendations
* Demand forecasting
* Fraud detection

We must process the data to extract this value.
How can we process all that information? There are actually two problems:
* large-scale data storage
* large-scale data analysis

## Limitations of traditional data storage and processing technologies

### Data Storage

> We want to look at Storage Capacity vs Price curve
> Next, we want to look at Storage Capacity vs Storage Performance (read performacne and write performance)
> The case in point is that, storage has gotten cheaper over the year but the performance hasn't improve just as much to scale for Peta bytes 

### Data Processing

> Monolithic Computing - limited scalability
> Distributed Computing - data is copied from storage nodes to the compute nodes, doesn't scale for big data use cases. Adds complexity in terms of consistency, synchronisation and failure handling

## Design Requirement for Big Data Systems

* Horizontal Scalability

* Concurrency 

* Consistency

* Programming Model

## Design Principles of Hadoop 

* Store and Process data on the same machines
    * seperate  storage and compute nodes create bottleneck
    * with this approach adding nodes increases both capacity and performance 

* Bring computation to data - Use intelligent job scheduling to process data on the same machine that stores it. This improves performance and conserves bandwidth.  

* Use multiple disks per host to circumvent disk performance bottleneck. Colocated storage and processing makes this feasible. 

* Simplified distributed programming model 

* Realise that failure is inevitable and instead try to minimise the effect of failure

## Hadoop Core Components

Hadoop is an architecture for large-scale (PBytes+) data storage and processing

Hadoop provides three core components:
* Hadoop Distributed File System (HDFS) for data storage
* MapReduce Programming Model for distributed data processing
* YARN Framework for Job Scheduling and Resource Management

Hadoop Ecosystem components include:
Data Processing - MapReduce, Spark
Data Discovery - Solr
Machine Learning - Mahout, MLlib
Data Warehouse - Hive
Data Ingestio - Flume, Sqoop
Data 






