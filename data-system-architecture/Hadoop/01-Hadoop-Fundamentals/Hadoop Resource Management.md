
# Anatomy of MapReduce Job Run using MapReduce 1

The classic Apache Hadoop MapReduce is composed of the **JobTracker**, which is the master, and the per-node slaves called **TaskTrackers**.


## JobTracker
it is responsible for resource management (managing the worker nodes i.e. TaskTrackers), tracking resource consumption/availability and also job life-cycle management (scheduling individual tasks of the job, tracking progress, providing fault-tolerance for tasks etc).


## TaskTracker
It is responsibile for launching/shuttingdown of tasks on orders from the JobTracker and provide task-status information to the JobTracker periodically.

## Limitations of Classic MapReduce approach
* **_Scalability_**: In the Classical MapReduce version there is a scalability issue as the JobTracker runs on a single host and takes care of both Cluster resource management and MapReduce application lifecycle model. Although there are mamy mode DataNodes available in the cluster, those are not getting used which limits scaliability.
    * Maximum cluster size: 4,000 nodes
    * Maximum concurrent tasks: 40,000


* **_Resource utilisation_**: In the classical MapReduce approach, there is a concept of pre-defined number of Map slots and Reduce slots for each TaskTrackers. Recouce Utilisation issues occur because map slots might be "full" while reduce slots are sitting idle (and vice versa).

* **_Single Point of Failure (SPOF)_**: If JobTracker fails, all queued and running jobs will fail. Jobs will be restarted once the cluster comes online.

* **_MapReduce only Data Processing_**: In the Classical MapReduce version there is a tight coupling between MapReduce programming model and Cluster resource management. JobTracker, which does resource management, is part of, MapReduce framework. Therefore, any client application can only use MapReduce paradigm for data processing.

# Apache Hadoop YARN Design Goals
YARN - Yet Another Resource Negotiator

YARN solves these limitations by adopting following design goals:

**_Segregation of services_**:
Splits up the two major functions of JobTracker:
  * cluster resource management
  * application lifecycle management

**_Scalability / resource pressure on the jobtracker_**:
YARN has a central resource manager component

**_Flexibility_**:
YARN framework is capable of executing jobs other than MapReduce

# Apache Hadoop YARN Architecture

Application:
- Application is a job submitted to the framework

Resource Manager
- Global resource scheduler
- 1 active per cluster

Node Manager
- Per-DataNode agent
- Manages the lifecycle of a container
- many (as many as DataNodes) per cluster

Container
- Basic unit of allocation, replacing the fixed unit of map/reduce slots in classical version

Application Master
- Per-application, manages application scheduling and task execution

JobHistory Server
- responsible for serving information about completed tasks
- 1 active per cluster

# Anatomy of MapReduce Job Run using MapReduce 2

- A client creates a job object using the same Java MapReduce API as in MRv1
- The client retrieves a new application ID from the resource manager
- The client calculates input splits and writes the job resources (e.g. jar file) on HDFS
- The client submits the job by calling submitApplication() procedure on the resource manager
- The resource manager allocates a container for the job execution purpose and launches the application master process on the node manager
- The application master initializes the job
- The application master retrieves the job resources from HDFS
- The application master requests for containers for tasks execution purpose from the resource manager
- The resource manager allocates tasks on containers based on a scheduler in use
- The containers launch a separate JVM for task execution purpose
- The containers retrieve the job resources and data from HDFS
- The containers periodically report progress and status updates to the application master
- The client periodically polls the application master for progress and status updates
- On the job completion the application master and the containers clean up their working state


# Job Scheduling

* Understand the overall design goals of each of Hadoop schedulers
* Given a scenario, determine how the FIFO Scheduler allocates cluster resources
* Given a scenario, determine how the Fair Scheduler allocates cluster resources under YARN
* Given a scenario, determine how the Capacity Scheduler allocates cluster resources

# YRN configuration deep dive
# YARN High Availability


Links:
http://saphanatutorial.com/how-yarn-overcomes-mapreduce-limitations-in-hadoop-2-0/

https://www.usenix.org/legacy/publications/login/2010-04/openpdfs/shvachko.pdf
