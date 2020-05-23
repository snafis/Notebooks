# Hadoop's differnt deployment modes
## Introduction
Hadoop can be configured to run in three different modes:
* LocalJobRunner mode
* Pseudo-distributed mode
* Fully distributed mode

## LocalJobRunner
In LocalJobRunner mode:
* no daemons run 
* Everything runs in a single Java Virtual Machine (JVM) 
* Hadoop uses the machine’s standard filesystem for data storage (i.e., Not "HDFS")
* Suitable for tes1ng MapReduce program (Developers can trace code in MapReduce jobs within an IDE)
* Only used by developers

## Pseudo-distributed
In pseudo-distributed mode:
* all daemons run on the local machine (Each runs in its own JVM (Java Virtual Machine))
* Hadoop uses HDFS to store data (by default) 
* Useful to simulate a cluster on a single machine 
* Convenient for debugging programs before launching them on the ‘real’ cluster 

## Fully distributed
In fully-distributed mode: 
* Hadoop daemons run on a cluster of machines 
* HDFS is used to distribute data amongst the nodes 
* Unless you are running a small cluster (less than 10 or 20 nodes), the NameNode, ResourceManager, and JobHistoryServer daemons should each be running on dedicated nodes. For small clusters, it’s acceptable for more than one of these daemons to run on the same physical node 
