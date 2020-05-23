# Building a Stream Data Platform (Part 1)

These days you hear a lot about "stream processing", "event data", and "real-time", often related to technologies like [Kafka][1], [Storm][2], [Samza][3], or Spark's [Streaming module][4]. Though there is a lot of excitement, not everyone knows how to fit these technologies into their technology stack or how to put it to use in practical applications.

This guide is going to discuss our experience with real-time data streams: how to build a home for real-time data within your company, and how to build applications that make use of that data. All of this is based on real experience: we spent the last five years building Apache Kafka, transitioning LinkedIn to a fully stream-based architecture, and helping a number of Silicon Valley tech companies do the same thing.

The first part of the guide will give a high-level overview of what we came to call a "stream data platform": a central hub for real-time streams of data. It will cover the what and why of this idea.

The second part will dive into a lot of specifics and give advice on how to put this into practice effectively.

But first, what is a stream data platform?

### The Stream Data Platform: A Clean, Well-lighted Place For Events

We built Apache Kafka at LinkedIn with a specific purpose in mind: to serve as a central repository of data streams. But why do this? There were two motivations.

The first problem was how to transport data between systems. We had lots of data systems: relational OLTP databases, Hadoop, Teradata, a search system, monitoring systems, OLAP stores, and derived key-value stores. Each of these needed reliable feeds of data in a geographically distributed environment. I'll call this problem "data integration", though we could also call it ETL.

The second part of this problem was the need to do richer analytical data processing—the kind of thing that would normally happen in a data warehouse or Hadoop cluster—but with very low latency. I call this "stream processing" though [others might call it][5] "messaging" or CEP or something similar.

I'll talk a little about how these ideas developed at LinkedIn. At first we didn't realize that these problems were connected at all. Our approach was very ad hoc: we built jerry-rigged piping between systems and applications on an as needed basis and shoe-horned any asynchronous processing into request-response web services. Over time this set-up got more and more complex as we ended up building pipelines between all kinds of different systems:

![data-flow-ugly][6]

Each of the pipelines was problematic in different ways. Our pipeline for log data was scalable but lossy and could only deliver data with high latency. Our pipeline between Oracle instances was fast, exact, and real-time, but not available to any other systems. Our pipeline of Oracle data for Hadoop was periodic CSV dumps—high throughput, but batch. Our pipeline of data to our search system was low latency, but unscalable and tied directly to the database. Our messaging systems were low latency but unreliable and unscalable.

As we added data centers geographically distributed around the world we had to build out geographical replication for each of these data flows. As each of these systems scaled, the supporting pipelines had to scale with them. Building simple duct tape pipelines had been easy enough but scaling these and operationalizing them was an enormous effort. I felt that my team, which was supposed to be made up of distributed systems engineers, was really acting more as distributed system plumbers.

Worse, the complexity meant that the data was always unreliable. Our reports were untrustworthy, derived indexes and stores were questionable, and everyone spent a lot of time battling data quality issues of all kinds. I remember an incident where we checked two systems that had similar data and found a discrepancy; we checked a third to try to determine which of these was correct and found that it matched neither.

At the same time we weren't just shipping data from place to place; we also wanted to do things with it. Hadoop had given us a platform for batch processing, data archival, and ad hoc processing, and this had been enormously successful, but we lacked an analogous platform for low-latency processing. Many applications— especially our monitoring systems, search indexing pipeline, analytics, and security and fraud analysis—required latency of no more than a few seconds. These types of applications had no natural home in our infrastructure stack.

So in 2010 we decided to build a system that would focus on capturing data as streams and use this as both the integration mechanism between systems and also allow real-time processing of these same data streams. This was the origin of Apache Kafka.

We imagined something like this:

![][7]

For a long time we didn't really have a name for what we were doing (we just called it "Kafka stuff" or "the global commit log thingy") but over time we came to call this kind of data "stream data", and the concept of managing this centrally a "stream data platform".

Our resulting system architecture went from the ugly spaghetti of pipelines I described before to a much cleaner stream-centric system:

&nbsp;

![A modern stream-centric data architecture built around Apache Kafka][8] A modern stream-centric data architecture built around Apache Kafka

In this setup Kafka acts as a kind of universal pipeline for data. Each system can feed into this central pipeline or be fed by it; applications or stream processors can tap into it to create new, derived streams, which in turn can be fed back into the various systems for serving. Continuous feeds of well-formed data act as a kind of _lingua franca_ across systems, applications, and data centers.

For example if a user updates their profile that update might flow into our stream processing layer where it would be processed to standardize their company information, geography, and other attributes. From there that stream might flow into search indexes and our social graph for querying, into a recommendation system for job matching; all of this would happen in milliseconds. This same flow would load into Hadoop to provide that data to the warehouse environment.

This usage at LinkedIn grew to phenomenal scale. Today at LinkedIn Kafka handles over 500 billion events per day spread over a number of data centers. It became the backbone for data flow between systems of all kinds, the core pipeline for Hadoop data, and the hub for stream processing.

Since Kafka was open source this usage spread beyond LinkedIn into [companies of all kinds][9] doing similar things.

In the rest of this article I'm going to outline a few details about this stream-centric world view, how it works, and what problems it solves.

### Streaming Data

Most of what a business does can be thought of as [streams of events][10]. Sometimes this is obvious. Retail has streams of orders, sales, shipments, price adjustments, returns, and so on. Finance has orders, stock prices, and other financial time series. Web sites have streams of clicks, impressions, searches, and so on. Big software systems have streams of requests, errors, machine metrics, and logs. Indeed one view of a business is as a kind of data processing system that takes various input streams and produces corresponding output streams (and maybe some physical goods along the way).

This view of data can seem a little foreign to people who are more accustomed to thinking of data as rows in databases rather than as events, so let's look at a few practical aspects of event data.

#### The Rise of Events and Event Streams

Your database stores the current state of your data. But the current state is always caused by some actions that took place in the past. The actions are the events. Your inventory table is the state that results from the purchase and sale events that have been made, bank balances are the result of credits and debits, and the latency graph for your web server is an aggregation of the stream of HTTP request times.

Much of what people refer to when they talk about "big data" is really the act of capturing these events that previously weren't recorded anywhere and putting them to use for analysis, optimization, and decision making. In some sense these events are the other half of the story the database tables don't tell: they are the story of what the business did.

Event data has always been present in finance, where stock ticks, market indicators, trades, and other time series data are naturally thought of as event streams.

But the tech industry popularized the most modern incarnation of technology for capture and use of this data. Google transformed the stream of ad clicks and ad impressions into a multi-billion dollar business. In the web space event data is often called "log data", because, lacking any proper infrastructure for their events, log files are often where the events are put. Systems like Hadoop are often described as being for "log processing", but that usage might be better described as batch event storage and processing.

Web companies were probably the earliest to do this because the process of capturing event data in a web site is very easy: a few lines of code can add tracking that records what users on a website did. As a result a single page load or mobile screen on a popular website is likely recording dozens or even hundreds of these events for analysis and monitoring.

You will sometimes hear about "machine generated data", but this is just event data by another name. In some sense virtually all data is machine generated, since it is made by computer systems.

Likewise there is a lot of talk about device data and the ["internet of things"][11]. This is a phrase that means a lot of things to different people, but a large part of the promise has to do with applying the same data collection and analytics of big web systems to industrial devices and consumer goods. In other words, more event streams.

#### Databases Are Event Streams

Event streams are an obvious fit for log data or things like "orders", "sales", "clicks" or "trades" that are obviously event-like. But, like most people, you probably keep much of your data in databases, whether relational databases like Oracle, MySQL, and Postgres, or newer distributed databases like MongoDB, Cassandra, and Couchbase. These would seem at first to be far removed from the world of events or streams.

But, in fact, data in databases can also be thought of as an event stream. The easiest way to understand the event stream representation of a database is to think about the process of creating a backup or standby copy of a database. A naive approach to doing this might be to dump out the contents of your database periodically, and load this up into the standby database. If we do this only infrequently, and our data isn't too large, than taking a full dump of all the data may be quite feasible. In fact many backup and ETL procedures do exactly this. However this approach won't scale as we increase the frequency of the data capture: if we do a full dump of data twice a day, it will take twice the system resources, and if we do it hourly, 24 times as much. The obvious approach to make this more efficient is to take a "diff" of what has changed and just fetch rows that have been newly created, updated, or deleted since our last diff was taken. Using this method, if we take our diffs twice as often, the diffs themselves will get (roughly) half as big, and the system resources will remain more or less the same as we increase the frequency of our data capture.

Why not take this process to the limit and take our diffs more and more frequently? If we do this what we will be left with is a continuous sequence of single row changes. This kind of event stream is called change capture, and is a common part of many databases systems (Oracle has XStreams and GoldenGate, MySQL has binlog replication, and Postgres has Logical Log Streaming Replication).

By publishing the database changes into the stream data platform you add this to the other set of event streams. You can use these streams to synchronize other systems like a Hadoop cluster, a replica database, or a search index, or you can feed these changes into applications or stream processors to directly compute new things off the changes. These changes are in turn published back as streams that are available to all the integrated systems.

### What Is a Stream Data Platform For?

A stream data platform has two primary uses:

1. **Data Integration**: The stream data platform captures streams of events or data changes and feeds these to other data systems such as relational databases, key-value stores, Hadoop, or the data warehouse.
2. **Stream processing**: It enables continuous, real-time processing and transformation of these streams and makes the results available system-wide.

In its first role, the stream data platform is a central hub for data streams. Applications that integrate don't need to be concerned with the details of the original data source, all streams look the same. It also acts as a buffer between these systems—the publisher of data doesn't need to be concerned with the various systems that will eventually consume and load the data. This means consumers of data can come and go and are fully decoupled from the source.

If you adopt a new system you can do this by tapping into your existing data streams rather than instrumenting each individual source system and application for each possible destination. The streams all look the same whether they originated in log files, a database, Hadoop, a stream processing system, or wherever else. This makes adding a new data system a much cheaper proposition—it need only integrate with the stream data platform not with every possible data source and sink directly.

A similar story is important for Hadoop which wants to be able to maintain a full copy of all the data in your organization and act as a "data lake" or "enterprise data hub". Directly integrating each data source with HDFS is a hugely time consuming proposition, and the end result only makes that data available to Hadoop. This type of data capture isn't suitable for real-time processing or syncing other real-time applications. Likewise this same pipeline can run in reverse: Hadoop and the data warehouse environment can publish out results that need to flow into appropriate systems for serving in customer-facing applications.

The stream processing use case plays off the data integration use case. All the streams that are captured for loading into Hadoop for archival are equally available for continuous "stream processing" as data is captured in the stream. The results of the stream processing are just a new, derived stream. This stream looks just like any other stream and is available for loading in all the data systems that have integrated with the stream data platform.

This stream processing can be done using simple application code that taps into the stream of events and publishes out a new stream of events. But this type of application code can be made easier with the help of a stream processing framework—such as Storm, Samza, or Spark Streaming—that helps provide richer processing primitives. These frameworks are just gaining prominence now, but each integrates well with Apache Kafka.

Stream processing acts as both a way to develop applications that need low-latency transformations but it is also directly part of the data integration usage as well: integrating systems often requires some munging of data streams in between.

### What Does a Stream Data Platform Need To Do?

I've discussed a number of different use cases. Each of these use cases has a corresponding event stream, but each stream has slightly different requirements—some need to be fast, some high-throughput, some need to scale out, etc. If we want to make a single platform that can handle all of these uses what will it need to do?

I think the following are the key requirements for a stream data platform:

* It must be reliable enough to handle critical updates such as replicating the changelog of a database to a replica store like a search index, delivering this data in order and without loss.
* It must support throughput high enough to handle large volume log or event data streams.
* It must be able to buffer or persist data for long periods of time to support integration with batch systems such as Hadoop that may only perform their loads and processing periodically.
* It must provide data with latency low enough for real-time applications.
* It must be possible to operate it as a central system that can scale to carry the full load of the organization and operate with hundreds of applications built by disparate teams all plugged into the same central nervous system.
* It has to support close integration with stream processing systems.

These requirements are necessary for this system to truly bring simplicity to data flow. The goal of the stream data platform is to sit at the heart of the company and manage these data streams. If the system cannot provide sufficient reliability guarantees or scale to large volume data then data will again end up fragmented over multiple systems. If the system cannot support both batch and real-time consumption, then again data will be fragmented. And if the system does not support operations at company-wide scale then silos will arise.

### What is Apache Kafka?

Apache Kafka is a distributed system designed for streams. It is built to be fault-tolerant, high-throughput, horizontally scalable, and allows geographically distributing data streams and processing.

Kafka is often categorized as a messaging system, and it serves a similar role, but provides a fundamentally different abstraction. The key abstraction in Kafka is a structured commit log of updates:

![commit_log][12]

A producer of data sends a stream of records which are appended to this log, and any number of consumers can continually stream these updates off the tail of the log with millisecond latency. Each of these data consumers has its own position in the log and advances independently. This allows a reliable, ordered stream of updates to be distributed to each consumer.

The log can be sharded and spread over a cluster of machines, and each shard is replicated for fault-tolerance. This gives a model for parallel, ordered consumption which is key to Kafka's use as a change capture system for database updates (which must be delivered in order).

Kafka is built as a modern distributed system. Data is replicated and partitioned over a cluster of machines that can grow and shrink transparently to the applications using the cluster. Consumers of data can be scaled out over a pool of machines as well and automatically adapt to failures in the consuming processes.

A key aspect of Kafka's design is that it handles persistence well. A Kafka broker can store many TBs of data. This allows usage patterns that would be impossible in a traditional database:

* A Hadoop cluster or other offline system that is fed off Kafka can go down for maintenance and come back hours or days later confident that all changes have been safely persisted in the up-stream Kafka cluster.
* When synchronizing from database tables it is possible to initialize a "full dump" of the database so that downstream consumers of data have access to the full data set.

These features make Kafka applicable well beyond the uses of traditional enterprise messaging systems.

### Event-driven Applications

Since we built Kafka as an open source project we have had the opportunity to work closely with companies who put it to use and to see the general pattern of Kafka adoption: how it first is adopted and how its role evolves over time in their architecture.

The initial adoption is usually for a single particularly large-scale use case: Log data, feeds into Hadoop, or other data streams beyond the capabilities of their existing messaging systems or infrastructure.

From there, though, the usage spreads. Though the initial use case may have been feeding a Hadoop cluster, once there is a continual feed of events available, the use cases for processing these events in real-time quickly emerge. Existing applications will end up tapping into the event streams to react to what is happening more intelligently, and new applications will be built to harness intelligence derived off these streams.

For example at LinkedIn we originally began capturing a stream of views to jobs displayed on the website as one of many feeds to deliver to Hadoop and our relational data warehouse. However this ETL-centric use case soon became one of many and the stream of job views over time began to be used by a variety of systems:

![job-view][13]

Note that the application that showed jobs didn't need any particular modification to integrate with these other uses. It just produced the stream of jobs that were viewed. The other applications tapped into this stream to add their own processing. Likewise when job views began happening in other applications—mobile applications—these are just added to the global feed of events, the downstream processors don't need to integrate with new upstream sources.

### How Does a Stream Data Platform Relate To Existing Things

Let's talk briefly about the relationship this stream data platform concept has with other things in the world.

##### Messaging

A stream data platform is similar to an enterprise messaging system—it receives messages and distributes them to interested subscribers. There are three important differences:

1. Messaging systems are typically run in one-off deployments for different applications. The purpose of the stream data platform is very much as a central data hub.
2. Messaging systems do a poor job of supporting integration with batch systems, such as a data warehouse or a Hadoop cluster, as they have limited data storage capacity.
3. Messaging systems do not provide semantics that are easily compatible with rich stream processing.

In other words a data stream data platform is a messaging system whose role has been rethought at a company-wide scale.

##### Data Integration Tools

A data stream data platform does a lot to make integration between systems easier. However its role is different from a tool like Informatica. A stream data platform is a true platform that any other system can choose to tap into and many applications can build around.

One practical area of overlap is that by making data available in a uniform format in a single place with a common stream abstraction, many of the routine data clean-up tasks can be avoided entirely. I'll dive into this more in the second part of this article.

##### Enterprise Service Buses

I think a data stream data platform embodies many of the ideas of an enterprise service bus, but with better implementation. The challenges of Enterprise Service Bus adoption has been the coupling of transformations of data with the bus itself. Some of the challenges of Enterprise Service Bus adoption are that much of the logic required for transformation are baked into the message bus itself without a good model for multi-tenant cloud like deployment and operation of this logic.

The advantage of a stream data platform is that transformation is fundamentally decoupled from the stream itself. This code can live in applications or stream processing tasks, allowing teams to iterate at their own pace without a central bottleneck for application development.

##### Change Capture Systems

Databases have long had similar log mechanisms such as Golden Gate. However these mechanisms are limited to database changes only and are not a general purpose event capture platform. They tend to focus primarily on the replication between databases, often between instances of the same database system (e.g. Oracle-to-Oracle).

##### Data Warehouses and Hadoop

A stream data platform doesn't replace your data warehouse; in fact, quite the opposite: it feeds it data. It acts as a conduit for data to quickly flow into the warehouse environment for long-term retention, ad hoc analysis, and batch processing. That same pipeline can run in reverse to publish out derived results from nightly or hourly batch processing.

##### Stream Processing Systems

Stream processing frameworks such as Storm, Samza, or Spark Streaming can be an excellent addition to the data stream data platform. They attempt to add richer processing semantics to subscribers and can make implementing data transformation easier.

Of course data transformation doesn't require a specialized system. Normal application code can subscribe to streams, process them, and write back derived streams, just as one does in one of these fancier systems. However these frameworks can potentially make this kind of processing easier.

### What Does This Look Like In Practice?

One of the interesting things about this concept is that it isn't just an idea, we have actually had the opportunity to "do the experiment". We spent the last five years building Kafka and helping companies put streaming data to use. At a number of Silicon Valley companies today you can see this concept in action—everything from user activity to database changes to administrative actions like restarting a process are captured in real-time streams that are subscribed to and processed in real-time.

What is interesting about this is that what begins as simple plumbing quickly evolves into something much more. These data streams begin to act as a kind of central nervous system that applications organize themselves around.


### Next Steps

We think this technology is changing how data is put to use in companies. We are building the Confluent Platform, a set of tools aimed at helping companies adopt and use Apache Kafka in this way. We think the Confluent Platform represents the best place to get started if you are thinking about putting streaming data to use in your organization.

There are a few other resources that may be useful:

1. I have previously written a [blog post][14] and short [book][15] about some of the ideas in this article focused on the relationship between Kafka's log abstraction, data streams, and data infrastructure.
2. Kafka's [documentation][16] goes into more detail on what it provides.
3. You can find out more about the [Confluent Platform][17] here.

The [second half][18] of this guide will cover some of the practical aspects of building out and managing a stream data platform.

[1]: http://kafka.apache.org/ "Apache Kafka"
[2]: https://storm.apache.org/ "Apache Storm"
[3]: http://samza.apache.org/ "Apache Samza"
[4]: https://spark.apache.org/streaming/ "Spark Streaming"
[5]: http://blog.confluent.io/2015/01/29/making-sense-of-stream-processing/ "Stream Processing, Event Sourcing, Reactive, CEP, and Making Sense of it All"
[6]: //cdn2.hubspot.net/hub/540072/file-3062870508-png/blog-files/data-flow-ugly.png?t=1452192137317&amp;width=660&amp;height=369
[7]: //cdn2.hubspot.net/hub/540072/file-3062870518-png/blog-files/stream_data_platform.png?t=1452192137317&amp;width=660&amp;height=395
[8]: //cdn2.hubspot.net/hub/540072/file-3062870528-png/blog-files/stream-centric-architecture1.png?t=1452192137317&amp;width=660&amp;height=528
[9]: https://cwiki.apache.org/confluence/display/KAFKA/Powered+By
[10]: http://blog.confluent.io/2015/01/29/making-sense-of-stream-processing/
[11]: http://en.wikipedia.org/wiki/Internet_of_Things
[12]: //cdn2.hubspot.net/hub/540072/file-3062870538-png/blog-files/commit_log-copy.png?t=1452192137317&amp;width=597&amp;height=265
[13]: //cdn2.hubspot.net/hub/540072/file-3062870548-png/blog-files/job-view.png?t=1452192137317&amp;width=506&amp;height=322
[14]: http://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying
[15]: http://shop.oreilly.com/product/0636920034339.do
[16]: http://kafka.apache.org/documentation.html
[17]: http://confluent.io
[18]: http://blog.confluent.io/stream-data-platform-2
  


Reference

[Source](http://www.confluent.io/blog/stream-data-platform-1/ "Permalink to A Practical Guide to Building a Stream Data Platform (Part 1)")
