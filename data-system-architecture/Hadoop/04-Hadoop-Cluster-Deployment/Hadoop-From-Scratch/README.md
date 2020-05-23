### Impala Installation in Ubuntu

Step 1 :- Install Impala

```bash
$ sudo apt-get install impala             # Binaries for daemons
$ sudo apt-get install impala-server      # Service start/stop script
$ sudo apt-get install impala-state-store # Service start/stop script
$ sudo apt-get install impala-catalog     # Service start/stop script
```

Step 2 :- Copy the client hive-site.xml, core-site.xml, hdfs-site.xml, and hbase-site.xml configuration files to the Impala configuration directory, which defaults to /etc/impala/conf. Create this directory if it does not already exist. 

```bash
$ sudo cp /etc/hadoop/conf/*.xml  /etc/impala/conf
$ sudo cp /etc/hive/conf/*.xml  /etc/impala/conf
$ sudo cp /etc/hbase/conf/*.xml  /etc/impala/conf
```

Step 3 :- Use  following commands to install impala-shell on the machines from which you want to issue queries. You can install impala-shell on any supported machine that can connect to DataNodes that are running impalad. 

```bash
$ sudo apt-get install impala-shell
```
Step 4 :- Post installation configuration

4.1. To configure DataNodes for short-circuit reads with CDH 4.2 or later:
On all Impala nodes, configure the following properties in Impala's copy of hdfs-site.xml as shown: 
[
Short-circuit reads make use of a UNIX domain socket. This is a special path in the filesystem that allows the client and the DataNodes to communicate. You will need to set a path to this socket. The DataNode needs to be able to create this path. On the other hand, it should not be possible for any user except the hdfs user or root to create this path. For this reason, paths under /var/run or /var/lib are often used.
Short-circuit local reads need to be configured on both the DataNode and the client.
]

```bash
$ sudo gedit /etc/impala/conf/hdfs-site.xml

<property>
    <name>dfs.client.read.shortcircuit</name>
    <value>true</value>
</property>

<property>
    <name>dfs.domain.socket.path</name>
    <value>/var/run/hadoop-hdfs/dn._PORT</value>
</property>

<property>
    <name>dfs.client.file-block-storage-locations.timeout.millis</name>
    <value>10000</value>
</property>
``` 
 
 
[Note: The text _PORT appears just as shown; you do not need to
        substitute a number.
If /var/run/hadoop-hdfs/ is group-writable, make sure its group
        is root or hdfs.
This is a path to a UNIX domain socket that will be used for
    communication between the DataNode and local HDFS clients.
    If the string "_PORT" is present in this path, it will be replaced by the
    TCP port of the DataNode.
  ] 
[
<property>
    <name>dfs.domain.socket.path</name>
    <value>/var/run/hdfs-sockets/dn</value>
</property>
this configuration also works 
]


 
To enable block location tracking:
For each DataNode, adding the following to the hdfs-site.xml file:

```xml
<property>
  <name>dfs.datanode.hdfs-blocks-metadata.enabled</name>
  <value>true</value>
</property> 
```
 
4.2. Set IMPALA_CONF_DIR environment variable
 
$ sudo gedit .bashrc
 
export IMPALA_CONF_DIR=/etc/impala/conf 
 

 
4.3. Modify hdfs-site.xml file in  /etc/hadoop/conf like below

```xml 
<property>
    <name>dfs.client.read.shortcircuit</name>
    <value>true</value>
</property>

<property>
    <name>dfs.domain.socket.path</name>
    <value>/var/run/hadoop-hdfs/dn._PORT</value>
</property>

<property>
    <name>dfs.client.file-block-storage-locations.timeout.millis</name>
    <value>10000</value>
</property>
 
<property>
  <name>dfs.datanode.hdfs-blocks-metadata.enabled</name>
  <value>true</value>
</property>  
```
[
Mandatory: Block Location Tracking
Enabling block location metadata allows Impala to know which disk data blocks are located on, allowing better utilization of the underlying disks. Impala will not start unless this setting is enabled
] 
 
Restart all the datanodes... 
 
 Start the statestore service using a command similar to the following:

`$ sudo service impala-state-store start`

Start the catalog service using a command similar to the following:

`$ sudo service impala-catalog start`

Start the Impala service on each data node using a command similar to the following:

`$ sudo service impala-server start`
 
Log in to Impala Shell
 
`impala-shell -i localhost `
 
Step 5 :- Configuring Impala with ODBC
Step 6 :- Configuring Impala with ODBC 
Step 7 :- Starting Impala
Step 8 :- Impala Security Configuration 
Step 9 :- Modifying Impala Startup Option
