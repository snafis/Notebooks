# Hadoop Distributed File System

## Background and Motivation

Traditional large storage area networks (SANs) and network attached storage (NAS) offer centralized, low-latency access to either a block device or a filesystem on the order of terabytes in size. These systems are fantastic as the backing store for relational databases, content delivery systems, and similar types of data storage needs because they can support full-featured POSIX semantics, scale to meet the size requirements of these systems, and offer low-latency access to data. Imagine for a second, though, hundreds or thousands of machines all waking up at the same time and pulling hundreds of terabytes of data from a centralized storage system at once. This is where traditional storage doesn’t necessarily scale.

By creating a system composed of independent machines, each with its own I/O sub- system, disks, RAM, network interfaces, and CPUs, and relaxing (and sometimes re- moving) some of the POSIX requirements, it is possible to build a system optimized, in both performance and cost, for the specific type of workload we’re interested in.

The Hadoop Distributed File System (HDFS)—a subproject of the Apache Hadoop project—is a distributed, highly fault-tolerant file system designed to run on low-cost commodity hardware. HDFS provides high-throughput access to application data and is suitable for applications with large data sets. This article explores the primary features of HDFS and provides a high-level view of the HDFS architecture.

## Design Assumptions and Goals

* **Hardware Failure**  
Hardware failure is the norm rather than the exception. An HDFS instance may consist of hundreds or thousands of server machines, each storing part of the file system’s data. The fact that there are a huge number of components and that each component has a non-trivial probability of failure means that some component of HDFS is always non-functional. Therefore, detection of faults and quick, automatic recovery from them is a core architectural goal of HDFS.

* **Streaming Data Access**  
Applications that run on HDFS need streaming access to their data sets. They are not general purpose applications that typically run on general purpose file systems. HDFS is designed more for batch processing rather than interactive use by users. The emphasis is on high throughput of data access rather than low latency of data access. POSIX imposes many hard requirements that are not needed for applications that are targeted for HDFS. POSIX semantics in a few key areas has been traded to increase data throughput rates.

* **Large Data Sets**
Applications that run on HDFS have large data sets. A typical file in HDFS is gigabytes to terabytes in size. Thus, HDFS is tuned to support large files. It should provide high aggregate data bandwidth and scale to hundreds of nodes in a single cluster. It should support tens of millions of files in a single instance.

* **Simple Coherency Model**
HDFS applications need a write-once-read-many access model for files. A file once created, written, and closed need not be changed. This assumption simplifies data coherency issues and enables high throughput data access. A MapReduce application or a web crawler application fits perfectly with this model. There is a plan to support appending-writes to files in the future.

* **“Moving Computation is Cheaper than Moving Data”**
A computation requested by an application is much more efficient if it is executed near the data it operates on. This is especially true when the size of the data set is huge. This minimizes network congestion and increases the overall throughput of the system. The assumption is that it is often better to migrate the computation closer to where the data is located rather than moving the data to where the application is running. HDFS provides interfaces for applications to move themselves closer to where the data is located.

* **Portability Across Heterogeneous Hardware and Software Platforms**  
HDFS has been designed to be easily portable from one platform to another. This facilitates widespread adoption of HDFS as a platform of choice for a large set of applications.

<http://hadoop.apache.org/docs/r1.2.1/hdfs_design.html>



## Access and Integration

### CLI - Command Line Interface

### FUSE - Filesystem In Userspace

### REST - REpresentational State Transfer


```python
if (isAwesome){
  return true
}
```


To do:
Describe the function of HDFS Daemons
Describe the normal operation of an Apache Hadoop cluster, both in data storage and in data processing.
Identify current features of computing systems that motivate a system like Apache Hadoop.
Classify major goals of HDFS Design
Given a scenario, identify appropriate use case for HDFS Federation
Identify components and daemon of an HDFS HA-Quorum cluster
Analyze the role of HDFS security (Kerberos)
Determine the best data serialization choice for a given scenario
Describe file read and write paths
Identify the commands to manipulate files in the Hadoop File System Shell
