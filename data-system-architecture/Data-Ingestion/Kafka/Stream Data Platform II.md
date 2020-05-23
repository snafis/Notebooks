
# Building a Stream Data Platform (Part 2)

[Source](http://www.confluent.io/blog/stream-data-platform-2/ "Permalink to A Practical Guide to Building a Stream Data Platform (Part 2)")

This is the second part of our guide on streaming data and Apache Kafka. In [part one][1] I talked about the uses for real-time data streams and explained our idea of a stream data platform. The remainder of this guide will contain specific advice on how to go about building a stream data platform in your organization.

This advice is drawn from our experience building and implementing Kafka at LinkedIn and rolling it out across all the data types and systems there. It also comes from four years working with tech companies in Silicon Valley to build Kafka-based stream data platforms in their organizations.

This is meant to be a living document. As we learn new techniques, or new tools become available, I'll update it.

## Getting Started

Much of the advice in this guide covers techniques that will scale to hundreds or thousands of well formed data streams. No one starts with that, of course. Usually you start with one or two trial applications, often ones that have scalability requirements that make other systems less suitable. Even in this kind of limited deployment, though, the techniques described in this guide will help you to start off with good practices, which is critical as your usage expands.

Starting with something more limited is good, it let's you get a hands on feel for what works and what doesn't, so that, when broader adoption comes, you are well prepared for it.

## Recommendations

I'll give a set of general recommendations for streaming data and Kafka and then discuss some specifics of different types of data.

### Limit The Number of Clusters

In early experimentation phases it is normal to end up with a few different Kafka clusters as adoption occurs organically in different parts of the organization. However part of the promise of this approach to data management is having a central repository with the full set of data streams your organization generates. This works best when data is all in the same place.

This is similar to the recommendations given in data warehousing where the goal is to concentrate data in a central warehouse for simplicity and to enable uses that join together multiple data sources.

Likewise we have seen that storing stream data in the fewest number of Kafka clusters feasible has a great deal of value in simplifying system architecture. This means fewer integration points for data consumers, fewer things to operate, lower incremental cost for adding new applications, and makes it easier to reason about data flow.

The fewest number of clusters may not be one cluster. There are several reasons to end up with multiple clusters:

1. To keep activity local to a datacenter. As described later we recommend that all applications connect to a cluster in their local datacenter with mirroring between data centers done between these local data centers.
2. For security reasons. Kafka does not yet have security controls which often means implementing network level security and physically segregating data types.
3. For SLA control. Kafka has some multi-tenancy features but this story is not complete.

Our job as Kafka engineers is to remove the restrictions that force new cluster creation, but until we've done that beware of the above limitations.

### Pick A Single Data Format

Apache Kafka does not enforce any particular format for event data beyond a simple key/value model. It will work equally well with XML, JSON, or Avro. Our general philosophy is that it is not the role of data infrastructure systems to enforce this kind of policy, that is really an organizational choice.

However, though your infrastructure shouldn't make this choice for you, you _should_ make a choice! Mandating a single, company-wide data format for events is critical. The overall simplicity of integration comes not only from having stream data in a single system—Kafka—but also by making all data look similar and follow similar conventions. If each individual or application chooses a representation of their own preference—say some use JSON, others XML, and others CSV—the result is that any system or process which uses multiple data streams has to munge and understand each of these. Local optimization—choosing your favorite format for data you produce—leads to huge global sub-optimization since now each system needs to write N adaptors, one for each format it wants to ingest.

An analogy borrowed from a friend can help to explain why such a mundane thing as data format is worth fussing about. One of the few great successes in the integration of applications is the Unix command line tools. The Unix toolset all works together reasonably well despite the fact that the individual commands were written by different people over a long period of time. The standard for integrating these tools is newline delimited ASCII text, these can be strung together with a '|' which transmits a record stream using standard input and standard output. The stream data platform is actually not that far removed from this itself. It is a kind of modern Unix pipe implemented at the data center level and designed to support our new world of distributed, continually running programs.

Though surely newline delimited text is an inadequate format to standardize on these days, imagine how useless the Unix toolchain would be if each tool invented its own format: you would have to translate between formats every time you wanted to pipe one command to another.

Picking a single format, making sure that all tools and integrations use it, and holding firm on the use of this format across the board, is likely the single most important thing to do in the early implementation of your stream data platform. This stuff is fairly new, so if you are adopting it now sticking to the simplicity of a uniform data format should be easy.

#### The Mathematics of Simplicity

Together these two recommendations—limiting the number of clusters and standardizing on a single data format—bring a very real kind of simplicity to data flow in an organization.

By centralizing on a single infrastructure platform for data exchange which provides a single abstraction—the real-time stream—we dramatically simplify the data flow picture. Connecting all systems directly would look something like this:

![data-systems-point-to-point][2]

Whereas having this central stream data platform looks something like this:

![data-systems-sdp][3]

This doesn't just look simpler. In the first picture we are on a path to build two pipelines for data for each _pair_ of systems, whereas in the second we are just building an input and output connector for each system to the stream data pipeline. If we have 10 systems to fully integrate this is the difference between 200 pipelines and 20 (if each system did both input and output).

But this is not just about systems and pipelines. Data also has to be adapted between systems. Relational databases have one data model, Hadoop another, and things like document stores still others. Providing a pipeline for raw bytes between systems would not really reduce complexity if each system produced and consumed in its own format. We would be left with a Tower of Babel where the RDBMS needs a different format plug-in for each possible source system. Instead by having a single data format in our stream data platform we need only adapt each system to this data format and we limit the format conversions in the same way we did the number of systems.

This is not to imply that we will never want to process or transform data as it flows between systems—that, after all, is exactly what stream processing is all about—but we want to eliminate low-value syntactic conversions. Semantic changes, enrichment, and filtering, to produce derived data streams will still be quite important.

#### Use Avro as Your Data Format

Any format, be it XML, JSON, or ASN.1, provided it is used consistently across the board, is better than a mishmash of ad hoc choices.

But if you are starting fresh with Kafka, you should pick the best format to standardize on. There are many criteria here: efficiency, ease of use, support in different programming languages, and so on. In our own use, and in working with a few dozen companies, we have found [Apache Avro][4] to be easily the most successful format for stream data.

Avro has a JSON like data model, but can be represented as either JSON or in a compact binary form. It comes with a very sophisticated schema description language that describes data.

We think Avro is the best choice for a number of reasons:

1. It has a direct mapping to and from JSON
2. It has a very compact format. The bulk of JSON, repeating every field name with every single record, is what makes JSON inefficient for high-volume usage.
3. It is very fast.
4. It has great bindings for a wide variety of programming languages so you can generate Java objects that make working with event data easier, but it does not require code generation so tools can be written generically for any data stream.
5. It has a rich, extensible schema language defined in pure JSON
6. It has the best notion of compatibility for evolving your data over time.

Though it may seem like a minor thing handling this kind of metadata turns out to be one of the most critical and least appreciated aspects in keeping data high quality and easily useable at organizational scale.

One of the critical features of Avro is the ability to define a schema for your data. For example an event that represents the sale of a product might look like this:

    {
      "time": 1424849130111,
      "customer_id": 1234,
      "product_id": 5678,
      "quantity":3,
      "payment_type": "mastercard"
    }

It might have a schema like this that defines these five fields:

    {
      "type": "record",
      "doc":"This event records the sale of a product",
      "name": "ProductSaleEvent",
      "fields" : [
        {"name":"time", "type":"long", "doc":"The time of the purchase"},
        {"name":"customer_id", "type":"long", "doc":"The customer"},
        {"name":"product_id", "type":"long", "doc":"The product"},
        {"name":"quantity", "type":"int"},
        {"name":"payment",
         "type":{"type":"enum",
    	     "name":"payment_types",
                 "symbols":["cash","mastercard","visa"]},
         "doc":"The method of payment"}
      ]
    }

A real event, of course, would probably have more fields and hopefully better doc strings, but this gives their flavor.

Here is how these schemas will be put to use. You will associate a schema like this with each Kafka topic. You can think of the schema much like the schema of a relational database table, giving the requirements for data that is produced into the topic as well as giving instructions on how to interpret data read from the topic.

The schemas end up serving a number of critical purposes:

1. They let the producers or consumers of data streams know the right fields are need in an event and what type each field is.
2. They document the usage of the event and the meaning of each field in the "doc" fields.
3. They protect downstream data consumers from malformed data, as only valid data will be permitted in the topic.

The value of schemas is something that doesn't become obvious when there is only one topic of data and perhaps a single writer and maybe a proof-of-concept reader. However when critical data streams are flowing through the pipeline and dozens or hundreds of systems depend on this, simple tools for reasoning about data have enormous impact.

But first, you may be asking why we need schemas at all? Isn't the modern world of big data all about unstructured data, dumped in whatever form is convenient, and parsed later when it is queried?

##### The Need For Schemas

I will argue that schemas—when done right—can be a huge boon, keep your data clean, and make everyone more agile. Much of the reaction to schemas comes from two factors—historical limitations in relational databases that make schema changes difficult, and the immaturity of much of the modern distributed infrastructure which simply hasn't had the time yet to get to the semantic layer of modeling done .

Here is the case for schemas, point-by-point.

###### Robustness

One of the primary advantages of this type of architecture where data is modeled as streams is that applications are decoupled. Applications produce a stream of events capturing what occurred without knowledge of which things subscribe to these streams.

But in such a world, how can you reason about the correctness of the data? It isn't feasible to test each application that produces a type of data against each thing that uses that data, many of these things may be off in Hadoop or in other teams with little communication. Testing all combinations is infeasible. In the absence of any real schema, new producers to a data stream will do their best to imitate existing data but jarring inconsistencies arise—certain magical string constants aren't copied consistently, important fields are omitted, and so on.

###### Clarity and Semantics

Worse, the actual meaning of the data becomes obscure and often misunderstood by different applications because there is no real canonical documentation for the meaning of the fields. One person interprets a field one way and populates it accordingly and another interprets it differently.

Invariably you end up with a sort of informal plain english "schema" passed around between users of the data via wiki or over email which is then promptly lost or obsoleted by changes that don't update this informal definition. We found this lack of documentation lead to people guessing as to the meaning of fields, which inevitably leads to bugs and incorrect data analysis when these guesses are wrong.

Keeping an up-to-date doc string for each field means there is always a canonical definition of what that value means.

###### Compatibility

Schemas also help solve one of the hardest problems in organization-wide data flow: modeling and handling change in data format. Schema definitions just capture a point in time, but your data needs to evolve with your business and with your code. There will always be new fields, changes in how data is represented, or new data streams. This is a problem that databases mostly ignore. A database table has a single schema for all it's rows. But this kind of rigid definition won't work if you are writing many applications that all change at different times and evolve the schema of shared data streams. If you have dozens of applications all using a central data stream they simply cannot all update at once.

And managing these changes gets more complicated as more people use the data and the number of different data streams grows. Surely adding a new field is a safe change, but is removing a field? What about renaming an existing field? What about changing a field from a string to a number?

These problems become particularly serious because of Hadoop or any other system that stores the events. Hadoop has the ability to load data "as is" either with Avro or in a columnar file format like Parquet or ORC. Thus the loading of data from data streams can be made quite automatic, but what happens when there is a format change? Do you need to re-process all your historical data to convert it to the new format? That can be quite a large effort when hundreds of TBs of data are involved. How do you know if a given change will require this? Do you guess and wait to see what will break when the change goes to production?

Schemas make it possible for systems with flexible data format like Hadoop or Cassandra to track upstream data changes and simply propagate these changes into their own storage without expensive reprocessing. Schemas give a mechanism for reasoning about which format changes will be compatible and (hence won't require reprocessing) and which won't.

###### Schemas are a Conversation

I actually buy many arguments for flexible types. Dynamically typed languages have an important role to play. And arguably databases, when used by a single application in a service-oriented fashion, don't need to enforce a schema, since, after all, the service that owns the data is the real "schema" enforcer to the rest of the organization.

However data streams are different; they are a broadcast channel. Unlike an application's database, the writer of the data is, almost by definition, not the reader. And worse, there are many readers, often in different parts of the organization. These two groups of people, the writers and the readers, need a concrete way to describe the data that will be exchanged between them and schemas provide exactly this.

###### Schemas Eliminate The Manual Labor of Data Science

It is almost a truism that data science, which I am using as a short-hand here for "putting data to effective use", is 80% parsing, validation, and low-level data munging. Data scientists complain that their training spent too much time on statistics and algorithms and too little on regular expressions, xml parsing, and practical data munging skills. This is quite true in most organizations, but it is somewhat disappointing that there are people with PhDs in Physics spending their time trying to regular-expression date fields out of mis-formatted CSV data (that inevitably has commas inside the fields themselves).

This problem is particularly silly because the nonsense data isn't forced upon us by some law of physics, this data doesn't just arise out of nature. Whenever you have one team whose job is to parse out garbage data formats and try to munge together inconsistent inputs into something that can be analyzed, there is another corresponding team whose job is to generate that garbage data. And once a few people have built complex processes to parse the garbage, that garbage format will be enshrined forever and never changed. Had these two teams talked about what data was needed for analysis and what data was available for capture the entire problem could have been prevented.

The advantage isn't limited to parsing. Much of what is done in this kind of data wrangling is munging disparate representations of data from various systems to look the same. It will turn out that similar business activities are captured in dramatically different ways in different parts of the same business. Building post hoc transformations can attempt to coerce these to look similar enough to perform analysis. However the same thing is possible at data capture time by just defining an enterprise-wide schema for common activities. If sales occur in 14 different business units it is worth figuring out if there is some commonality among these that can be enforced so that analysis can be done over all sales without post-processing. Schemas won't automatically enforce this kind of thoughtful data modeling but they do give a tool by which you can enforce a standard like this.

##### At LinkedIn

We put this idea of schemafied event data into practice at large scale at LinkedIn. User activity events, metrics data, stream processing output, data computed in Hadoop, and database changes were all represented as streams of Avro events.

These events were automatically loaded into Hadoop. When a new Kafka topic was added that data would automatically flow into Hadoop and a corresponding Hive table would be created using the event schema. When the schema evolved that metadata was propagated into Hadoop. When someone wanted to create a new data stream, or evolve the schema for an existing one, the schema for that stream would undergo a quick review by a group of people who cared about data quality. This review would ensure this stream didn't duplicate an existing event and that things like dates and field names followed the same conventions, and so on. Once the schema change was reviewed it would automatically flow throughout the system. This leads to a much more consistent, structured representation of data throughout the organization.

Other companies we have worked with have largely come to the same conclusion. Many started with loosely structured JSON data streams with no schemas or contracts as these were the easiest to implement. But over time almost all have realized that this loose definition simply doesn't scale beyond a dozen people and that some kind of stronger metadata is needed to preserve data quality.

##### Back to Avro

Okay that concludes the case for schemas. We chose Avro as a schema representation language after evaluating all the common options—JSON, XML, Thrift, protocol buffers, etc. We recommend it because it is the best thought-out of these for this purpose. It has a pure JSON representation for readability but also a binary representation for efficient storage. It has an exact compatibility model that enables the kind of compatibility checks described above. It's data model maps well to Hadoop data formats and Hive as well as to other data systems. It also has bindings to all the common programming languages which makes it convenient to use programmatically.

Good overviews of Avro can be found [here][5] and [here][6].

We have built tools for implementing Avro with Kafka or other systems as part of the [Confluent Platform][7], you can read more about this schema support [here][8].

##### Effective Avro

Here are some recommendations specific to Avro:

* Use enumerated values whenever possible instead of magic strings. Avro allows specifying the set of values that can be used in the schema as an enumeration. This avoids typos in data producer code making its way into the production data set that will be recorded for all time.
* Require documentation for all fields. Even seemingly obvious fields often have non-obvious details. Try to get them all written down in the schema so that anyone who needs to really understand the meaning of the field need not go any further.
* Avoid non-trivial union types and recursive types. These are Avro features that map poorly to most other systems. Since our goal is an intermediate format that maps well to other systems we want to avoid any overly advanced features.
* Enforce reasonable schema and field naming conventions. Since these schemas will map into Hadoop having common fields like customer_id named the same across events will be very helpful in making sure that joins between these are easy to do. A reasonable scheme might be something like PageViewEvent, OrderEvent, ApplicationBounceEvent, etc.

### Share Event Schemas

Whenever you see a common activity across multiple systems try to use a common schema for this activity. Doing so often requires a small amount of thought, but it saves a lot of work in using the data.

An example of this that is common to all businesses is application errors. Application errors can generally be modeled in a fairly general way (say an error has a stack trace, an application name, an error message, and so on) and doing so lets the ErrorEvent stream capture the full stream of errors across the company. This means tools that process, alert, analyze, or report on errors will automatically extend to each new system that emits data to this stream. Had each application derived it's own data format for errors than each error consumer would need to somehow munge all the disparate error streams into a common format for processing or analytics.

This experience is common. Any time you can make similar things look similar by data modeling it is almost free to do so—you just need a schema—but every time you do this in post processing you need to maintain code to do this post-processing indefinitely.

A corollary to this is to avoid system or application names in event names. When adding event capture to a system, named, say, "CRS", there is a tendency to name every event with CRS as part of the name ("CRSOrderEvent", "CRSResendEvent", etc). However our experience was that systems tend to get replaced, while many many applications will end up feeding off the event stream. If you put the system name in the event stream name the source system can never change, or the new replacement system will have to produce data with the old name. Instead name events in a system and application agnostic way—just use the high-level business activity they represent. So if CRS is an order management system then just OrderEvent is sufficient.

## Modeling Specific Data Types In Kafka

### Pure Event Streams

Kafka's data model is built to represent event streams. A stream in Kafka is modeled by a topic, which is the logical name given to that data. Each message has a key, which is used to partition data over the cluster as well as a body which would contain the Avro record data (or whichever format you have chosen).

Kafka maintains a configurable history of the stream. This can be managed with an SLA (e.g. retain 7 days) or by size (e.g retain 100 GB) or by key (e.g. retain at least that last update for each key).

Let's begin with pure event data—the activities taking place inside the company. In a web company these might be clicks, impression, and various user actions. FedEx might have package deliveries, package pick ups, driver positions, notifications, transfers and so on.

These type of events can be represented with a single logical stream per action type. For simplicity I recommend naming the Avro schema and the topic the same thing, e.g. PageViewEvent. If the event has a natural primary key you can use that to partition data in Kafka, otherwise the Kafka client will automatically load balance data for you.

Pure event streams will always be retained by size or time. You can choose to keep a month or 100GB per stream or whatever policy you define.

We experimented at various times with mixing multiple events in a single topic and found this generally lead to undue complexity. Instead give each event it's own topic and consumers can always subscribe to multiple such topics to get a mixed feed when they want that.

By having a single schema for each topic you will have a much easier time mapping a topic to a Hive table in Hadoop, a database table in a relational DB or other structured stores.

### Application Logs

The term "logs" is somewhat undefined. It sometimes means error messages, stack traces, and warnings in semi-formated english such as a server might record in the course of request processing. It sometimes means fairly structured request logs like might come out of Apache HTTPD. It sometimes means event data which might be dumped to a log file.

For this section I will use "logs" to refer to the semi-structured application logs. Structured logs like request logs and other activity or event data should just be treated like any other event as described and should have a schema per activity that capture exactly the fields that make up that event.

However there can be some value in capturing application logs in Kafka as well. At LinkedIn all application logs were published to Kafka via a custom log4j appender for Java. These were loaded into Hadoop for batch analysis as well as being delivered to real-time tools that would subscribe to the stream of application logs for reporting on sudden error spikes or changes after new code was pushed. These errors were also joined back to the stream of service requests in a stream processing system so we could get a wholistic picture of utilization, latency, errors, and the [call patterns][9] amongst our services.

### System Metrics

We also published a stream of statistics about applications and servers. These had a common format across all applications. They captured things like unix performance statistics (the kind of I/O and CPU load you would get out of iostat or top) as well as application defined gauges and counters captured using things like JMX.

This all went into a central feed of monitoring statistics that fed the company wide monitoring platform. Any new system could integrate by publishing its statistics, and all statistics were available in a company-wide monitoring store.

### Derived Streams

Mostly so far we have talked about producing streams of events into Kafka. These events are things happening in applications or data systems. I'll call these "primary" data streams. However there is another type of data stream, a "derived" stream. These are streams that were computed off other data streams. This computation could be done in real-time as events occurred, either in an application or in a stream processing system, or it could be done periodically in Hadoop. These derived streams often do some kind of enrichment, say adding on new attributes not present in the original event.

Derived streams require no particular handling. They can be computed using simple programs that directly consume from Kafka and write back derived results or they can be computed using a stream processing system. Regardless which route is taken the output stream is just another Kafka topic so the consumer of the data need not be concerned with the mechanism used to produce it. A batch computed stream from Hadoop will look no different from a stream coming from a stream processing system, except that it will be higher latency.

### Hadoop Data Loads

There are many ways to load data from Kafka into Hadoop and there are many aspects of doing this well.

One of the most critical is doing it in a fully automated way. Since Hadoop will likely want to load data from _all_ the data streams you don't want to be doing any custom set-up or mappings between your Kafka topics and your Hadoop data sets and Hive tables.

We have packaged a simple system for doing this called Camus that came out of LinkedIn. It is described in more detail [here][10].

### Hadoop Data Publishing

The opposite of loading data into Hadoop is just as common. After all the purpose of Hadoop is to act as a computational engine, and whatever it computes must go somewhere for serving. Often this piping can be quite complex as the Hadoop cluster may not be physically co-located with the serving system, and even if it is you often don't want Hadoop writing directly to a database used for serving live requests as it will easily overwhelm such a system.

So the stream data platform is a great place to publish these derived streams from Hadoop. The stream data platform can handle the distribution of data across data centers. As far as the recipient is concerned this is just another stream which happens to receive updates only periodically.

This allows the same plugins that load data from a stream processor to also be used for loading Hadoop data. So an analytical job can begin its life in Hive and later migrate to a lower latency stream processing platform without needing to rewrite the serving layer.

### Database Changes

Database changes require some particular discussion. Database data is somewhat different from pure event streams in that it models updates—that is, rows that change.

The first and arguably most important issue is how changes are captured from the database. There are two common methods for doing this:

1. Polling for changes
2. Direct log integration with the database

Polling for changes requires little integration with the database so it is the easiest to implement. Polling requires some kind of last modified timestamp that can be used to detect new values so it requires some co-operation from the schema. There are also a number of gotchas in implementing correct change capture by polling. First, long running transactions can lead to rows that commit out of timestamp order when using simple time; this means that rows can appear in the near past. Many databases support some kind of logical change number that can help alleviate this problem. This method also doesn't guarantee that every change is captured, when multiple updates occur on a single row in between polling intervals only the last of these is delivered. It also doesn't capture deleted rows.

All the limitations of polling are fixed by direct integration with the database log, but the mechanism for integration is very database specific. MySQL has a binlog, Postgres has logical replication, Oracle has a number of products including Change Capture, Streams, XStreams, and Golden Gate, MongoDB has the oplog. These features range from deeply internal features like the MySQL binlog to full productized apis like XStreams. These log mechanisms will capture each change and have lower overhead than polling.

This is an area Confluent will be doing more work in the future.

#### Retaining Database Changes

For pure event data Kafka often retains just a short window of events, say a week of data. However for database change streams, systems will want to do full restores off of this Kafka changelog. Kafka does have a relevant feature that can help with this called [Log Compaction][11]. Log compaction ensures that rather than discarding data by time, Kafka will retain at least the final update for each key. This means that any client reading the full log from Kafka will get a full copy of the data and not need to disturb the database. This is useful for cases where there are many subscribers that may need to restore a full copy of data to prevent them from overwhelming the source database.

#### Extract Database Data As-is, Then Transform

Often databases have odd schemas specific to idiosyncrasies of their query pattern or internal implementation. Perhaps it stores data in odd key-value blobs. We would generally like to clean up this type of data for usage.

There are three ways we could do this clean-up:

1. As part of the extraction process
2. As a stream processor that reads the original data stream and produces a "cleaned" stream with a more sane schema
3. In one of the destination system

Pushing the clean-up to the consumer is not ideal as there can be many consumers so the work ends up being done over and over.

Clean up as part of the extraction is tempting, but often leads to problems. One person's clean-up is another business logic and not all clean-ups are reversible so important aspects of the source data may be lost in the cleaning process.

Our finding was that publishing the original data stream, what actually happened, had value; any additional clean-up could then be layered on top of that as a new stream of its own. This seems wasteful at first, but the reality is that this kind of storage is so cheap that it is often not a significant cost.

## Stream Processing

One of the goals of the stream data platform is being able to stream data between data systems. The other goal is to enable processing of data streams as data arrives.

Stream processing is easily modeled in the stream data platform as just a transformation between streams. A stream processing job continually reads from one or more data streams and outputs one or more data streams of output. These kind of processors can be strung together into a graph of flowing data:

![dag][12]

The particular method used to implement the processes that do the transformation is actually something of an implementation detail to the users of the output, though obviously it is an important detail to the implementor of the process.

Publishing data back into Kafka like this provides a number of benefits. First it decouples parts of the processing graph. One set of processing jobs may be written by one team and another by another. They may be built using different technologies. Most importantly we don't want a slow downstream processor to be able to cause back-pressure to seize up anything that feeds data to it. Kafka acts as this buffer between the processors that can let an organization happily share data.

The most basic approach is to directly use the Kafka APIs to read input data streams, process that input and produce output streams. This can be done in a simple program in any programming language. Kafka allows you to scale these out by running multiple instances of these programs, it will spread the load across these instances. Kafka guarantees at-least once delivery of data and these programs will inherit that guarantee.

The advantage of the simple, framework free approach is that it is simple to operate and reason about and available in any language that has good Kafka clients.

However there are several stream processing systems that can potentially provide additional features. Used in this fashion as processing between Kafka topics they generally can't give stronger guarantees or improve performance beyond what Kafka itself provides (though they can certainly make both worse). However building complex real-time processing can often be made simpler with a processing framework.

There are three common frameworks for stream processing:

Coincidentally all are Apache projects beginning with the letter "S"! Of the two Storm and Samza are somewhat comparable, being message at a time stream processing systems, while Spark is more of a mini-batch framework that applies the (very nice) Spark abstraction to smaller batches of data. There are comparisons between these systems [here][13] as well as [here][14] and [here][15].

So when should you use one of these stream processing frameworks?

Where these frameworks really shine is in areas where there will be lots of complex transformations. If there will be only a small number of processes doing transformations the cost of adopting a complex framework may not pay off, and the framework may come with operational and performance costs of their own. However if there will be a large number of transformations, making these easier to write should justify the additional operational burden.

Over time we think these frameworks will get more mature and more code will move into this stream processing domain, so the future of stream processing frameworks is quite bright.

## Have Any Streaming Experiences to Share?

That is it for my current list of data stream do's and don'ts. If you have additional recommendations to add to this, pass them on.

Meanwhile we're working on trying to put a lot of these best practices into software as part of the Confluent Platform which you can find out more about [here][7].

[1]: http://blog.confluent.io/stream-data-platform-1
[2]: //cdn2.hubspot.net/hub/540072/file-3062870603-png/blog-files/data-systems-point-to-point.png?t=1452192137317&amp;width=213&amp;height=221
[3]: //cdn2.hubspot.net/hub/540072/file-3062870613-png/blog-files/data-systems-sdp.png?t=1452192137317&amp;width=215&amp;height=227
[4]: http://avro.apache.org/docs/current/
[5]: http://martin.kleppmann.com/2012/12/05/schema-evolution-in-avro-protocol-buffers-thrift.html
[6]: http://radar.oreilly.com/2014/11/the-problem-of-managing-schemas.html
[7]: http://confluent.io/product
[8]: http://confluent.io/docs/current/schema-registry/docs/index.html
[9]: https://engineering.linkedin.com/samza/real-time-insights-linkedins-performance-using-apache-samza
[10]: http://confluent.io/docs/current/camus/docs/index.html
[11]: http://kafka.apache.org/documentation.html#compaction
[12]: //cdn2.hubspot.net/hub/540072/file-3062870623-png/blog-files/dag.png?t=1452192137317&amp;width=260&amp;height=266
[13]: http://www.javacodegeeks.com/2015/02/streaming-big-data-storm-spark-samza.html
[14]: http://samza.apache.org/learn/documentation/0.7.0/comparisons/spark-streaming.html
[15]: http://samza.apache.org/learn/documentation/0.7.0/comparisons/storm.html
  
