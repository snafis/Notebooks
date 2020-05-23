# Cluster Benchmarking

* [TeraSort Suite: teragen, terasort, teravalidate](http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench/#terasort-benchmark-suite)
![TeraStort Suite](http://www.michael-noll.com/blog/uploads/hadoop-benchmarking-terasort-data-flow1-505x600.png)

``` ruby
sudo -u hdfs hadoop jar /opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar teragen 20000000 /teraInput
sudo -u hdfs hadoop jar /opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar terasort /teraInput /teraOutput
sudo -u hdfs hadoop jar /opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar teravalidate /teraOutput /teraValidate
```


* A few use [TestDFSIO](http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench/#testdfsio)
* For more robust performance testing    
    * [<strong>S</strong>tatistical <strong>W</strong>orkload <strong>I</strong>njector for <strong>M</strong>apReduce](https://github.com/SWIMProjectUCB/SWIM/wiki) (SWIM)    
    * Used by Cloudera's Partner Engineering
    * Not a ready-to-deploy field tool
* Consider testing the NameNode first: [nnbench](http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench/#namenode-benchmark-nnbench)



## Reference

[Michael G. Noll's blog post](http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench/) reviews many of these tools (not SWIM).
