# Installing and Deploying CDH Using the Command Line

## Pre-requisite

Before you install CDH 5 on a cluster, there are some important steps you need to do to prepare your system:

* Verify you are using a supported operating system for CDH 5. [Add Link: where to find os compatibility info]
* If you install the Oracle Java Development Kit. [Add Link: How to do this]


## Creating a Local Yum Repository

To set up your own internal mirror, follow the steps below. You need an internet connection for the steps that require you to download packages and create the repository itself. You will also need an internet connection in order to download updated RPMs to your local repository.


### Navigate to the repos directory and download the cloudera repo file there.

``` ruby
cd /etc/yum.repos.d/
wget http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
```

For reference, the repo like looks like this:

```
[cloudera-cdh5]
# Packages for Cloudera's Distribution for Hadoop, Version 5, on RedHat	or CentOS 6 x86_64
name=Cloudera's Distribution for Hadoop, Version 5
baseurl=http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/5/
gpgkey = http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
gpgcheck = 1
```


### Install a web server such as apache/lighttpd on the machine which will serve the RPMs.

> **Note:** The default configuration should work. HTTP access must be allowed to pass through any firewalls between this server and the internet connection.

``` ruby
# installing apache
sudo yum install httpd
# registering httpd service
chkconfig httpd on
# starting httpd service
/etc/init.d/httpd start
# confirming server setup
netstat -tulpn | grep :80
ps -ef | grep httpd
httpd -V
```


### On the server with the web server,, install the yum-utils and createrepo RPM packages if they are not already installed.

The yum-utils package includes the reposync command, which is required to create the local Yum repository.

``` ruby
sudo yum install yum-utils createrepo
```


### On the same computer as in the previous steps, download the yum repository into a temporary location

``` ruby
reposync -r cloudera-cdh5
```

### Put all the RPMs into a directory served by your web server

Such as /var/www/html/cdh/5/RPMS/noarch/ (or x86_64 or i386 instead of noarch). The directory structure 5/RPMS/noarch is required. Make sure you can remotely access the files in the directory via HTTP, using a URL similar to http://<yourwebserver>/cdh/5/RPMS/).

### On your web server, issue the following command from the 5/ subdirectory of your RPM directory:

``` ruby
createrepo .
```

### Edit the repo file you downloaded in step 1

replace the line starting with baseurl= or mirrorlist= with baseurl=http://<yourwebserver>/cdh/5/, using the URL from step 5. Save the file back to /etc/yum.repos.d/.


### While disconnected from the internet, issue the following commands to install CDH from your local yum repository.

``` ruby
yum clean all
yum update
yum install hadoop
```

### Once you have confirmed that your internal mirror works, you can distribute this modified repo file to any system which can connect to your repository server. Those systems can now install CDH from your local repository without internet access.

yum clean all
yum update


### Optionally Add a Repository Key
``` ruby
sudo rpm --import http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
```

## Install CDH 5 with YARN

### Install and deploy ZooKeeper host
```
sudo yum clean all
sudo yum install zookeeper
```

### Install and deploy Resource Manager host

```
sudo yum clean all
sudo yum install hadoop-yarn-resourcemanager
```

### Install and deploy NameNode host

```
sudo yum clean all
sudo yum install hadoop-hdfs-namenode
```

### Install and deploy Secondary NameNode host

```
sudo yum clean all
sudo yum install hadoop-hdfs-secondarynamenode
```

### Install and deploy on all cluster hosts except the Resource Manager host

```
sudo yum clean all
sudo yum install hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce
```

### One host in the cluster

```
sudo yum clean all
sudo yum install hadoop-mapreduce-historyserver hadoop-yarn-proxyserver
```

### All client hosts

```
sudo yum clean all
sudo yum install hadoop-client
```

### (Optional) Install LZO

Save the following file in the /etc/yum.repos.d/ directory

```
[cloudera-gplextras5]
# Packages for Cloudera's GPLExtras, Version 5, on RedHat or CentOS 6 x86_64
name=Cloudera's GPLExtras, Version 5
baseurl=http://archive.cloudera.com/gplextras5/redhat/6/x86_64/gplextras/5/
gpgkey = http://archive.cloudera.com/gplextras5/redhat/6/x86_64/gplextras/RPM-GPG-KEY-cloudera
gpgcheck = 1
```

```
sudo yum install hadoop-lzo
```


## Deploying CDH5 Core Components


### Configure Network Host

Enabling NTP

``` ruby
# install NTP
sudo yum install ntp
# Open the /etc/ntp.conf file and add NTP servers
server 0.pool.ntp.org
server 1.pool.ntp.org
server 2.pool.ntp.org
# Configure the NTP service to run at reboot.
chkconfig ntpd on
# Start the NTP service
service ntpd start
# Synchronize the node
ntpdate -u <your_ntp_server>
# Synchronize the system clock (to prevent synchronization problems).
hwclock --systohc
```

Configuring Network Names
``` ruby
# Set the hostname of each system to a unique name
sudo hostname myhost-1

# Make sure the /etc/hosts file on each system contains the IP addresses and fully-qualified domain names (FQDN) of all the members of the cluster
127.0.0.1         localhost.localdomain     localhost
193.186.1.81      cluster2.example.com      cluster2
10.0.0.1          ecluster2.example.com     ecluster2
193.186.1.82      cluster3.example.com      cluster3
10.0.0.2          ecluster3.example.com     ecluster3

# Make sure the /etc/sysconfig/network file on each system contains the hostname you have just set


# Check that this system is consistently identified to the network:

# Run uname -a and check that the hostname matches the output of the hostname command.


# Run /sbin/ifconfig and note the value of inet addr in the eth0 entry
sbin/ifconfig
eth0      Link encap:Ethernet  HWaddr 00:0C:29:A4:E8:97  
          inet addr:172.29.82.176  Bcast:172.29.87.255  Mask:255.255.248.0
...

# Run host -v -t A `hostname` and make sure that hostname matches the output of the hostname command
host -v -t A `hostname`
Trying "myhost.mynet.myco.com"
...
;; ANSWER SECTION:
myhost.mynet.myco.com. 60 IN	A	172.29.82.176

```



Disabling SELinux
> Add link: how to disable SELinux

```
# Check the SELinux state
getenforce
setenforce 0
```


Disabling the Firewall

To disable the firewall on each host in your cluster, perform the following steps on each host.

```
# Save the existing iptables rule set
iptables-save > /root/firewall.rules
# Disable iptables.
chkconfig iptables off
/etc/init.d/iptables stop
```

## Deploying HDFS on a Cluster

Proceed as follows to deploy HDFS on a cluster. Do this for all clusters, whether you are deploying MRv1 or YARN:

Copying the Hadoop Configuration and Setting Alternatives

```
# Copy the default configuration to your custom directory:
sudo cp -r /etc/hadoop/conf.empty /etc/hadoop/conf.my_cluster

# Configure CDH to use the configuration in /etc/hadoop/conf.my_cluster, as follows.
sudo alternatives --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.my_cluster 50
sudo alternatives --set hadoop-conf /etc/hadoop/conf.my_cluster
sudo alternatives --display hadoop-conf
> hadoop-conf - status is auto.
> link currently points to /etc/hadoop/conf.my_cluster
> /etc/hadoop/conf.my_cluster - priority 50
> /etc/hadoop/conf.empty - priority 10
> Current `best' version is /etc/hadoop/conf.my_cluster.
```

Customizing Configuration Files

**core-site.xml:**
``` xml
<property>
 <name>fs.defaultFS</name>
 <value>hdfs://namenode-host.company.com:8020</value>
</property>
```

**hdfs-site.xml:**
``` xml
<property>
 <name>dfs.permissions.superusergroup</name>
 <value>hadoop</value>
 <name>dfs.namenode.name.dir</name>
 <value>file:///data/1/dfs/nn,file:///nfsmount/dfs/nn</value>
 <name>dfs.datanode.data.dir</name>
 <value>file:///data/1/dfs/dn,file:///data/2/dfs/dn,file:///data/3/dfs/dn,file:///data/4/dfs/dn</value>
</property>
```

After specifying these directories as shown above, you must create the directories and assign the correct file permissions to them on each node in your cluster.

``` ruby
sudo mkdir -p /data/1/dfs/nn /nfsmount/dfs/nn
sudo mkdir -p /data/1/dfs/dn /data/2/dfs/dn /data/3/dfs/dn /data/4/dfs/dn
sudo chown -R hdfs:hdfs /data/1/dfs/nn /nfsmount/dfs/nn /data/1/dfs/dn /data/2/dfs/dn /data/3/dfs/dn /data/4/dfs/dn
sudo chmod 700 /data/1/dfs/nn /nfsmount/dfs/nn
```


Configuring DataNodes to Tolerate Local Storage Directory Failure
dfs.datanode.failed.volumes.tolerated


Formatting the NameNode
Before starting the NameNode for the first time you need to format the file system.

```
sudo -u hdfs hdfs namenode -format
> Re-format filesystem in /data/namedir ? (Y or N)
> Note: Respond with an upper-case Y; if you use lower case, the process will abort.
```

> TO DO: Other configs


## Deploy HDFS

``` ruby
# Push your custom directory (for example /etc/hadoop/conf.my_cluster) to each node in your cluster; for example:
scp -r /etc/hadoop/conf.my_cluster myuser@myCDHnode-<n>.mycompany.com:/etc/hadoop/conf.my_cluster

# Manually set alternatives on each node to point to that directory, as follows.
sudo alternatives --verbose --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.my_cluster 50
sudo alternatives --set hadoop-conf /etc/hadoop/conf.my_cluster

# Start HDFS on each node in the cluster, as follows:
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

# Create the /tmp directory
sudo -u hdfs hadoop fs -mkdir /tmp
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp

```

## Deploy YARN


Step 1: Configure Properties for YARN Clusters

**mapred-site.xml:**

``` xml
<property>
 <name>mapreduce.framework.name</name>
 <value>yarn</value>
</property>
```
``` xml
Step 2: Configure YARN daemons

**yarn-site.xml:**

<property>
  <name>yarn.resourcemanager.hostname</name>
  <value>resourcemanager.company.com</value>
</property>
<property>
  <description>Classpath for typical applications.</description>
  <name>yarn.application.classpath</name>
  <value>
      $HADOOP_CONF_DIR,
      $HADOOP_COMMON_HOME/*,$HADOOP_COMMON_HOME/lib/*,
      $HADOOP_HDFS_HOME/*,$HADOOP_HDFS_HOME/lib/*,
      $HADOOP_MAPRED_HOME/*,$HADOOP_MAPRED_HOME/lib/*,
      $HADOOP_YARN_HOME/*,$HADOOP_YARN_HOME/lib/*
  </value>
</property>
<property>
  <name>yarn.nodemanager.aux-services</name>
  <value>mapreduce_shuffle</value>
</property>
<property>
  <name>yarn.nodemanager.local-dirs</name>
  <value>file:///data/1/yarn/local,file:///data/2/yarn/local,file:///data/3/yarn/local</value>
</property>
<property>
  <name>yarn.nodemanager.log-dirs</name>
  <value>file:///data/1/yarn/logs,file:///data/2/yarn/logs,file:///data/3/yarn/logs</value>
</property>
<property>
  <name>yarn.log.aggregation-enable</name>
  <value>true</value>
</property>  
<property>
  <description>Where to aggregate logs</description>
  <name>yarn.nodemanager.remote-app-log-dir</name>
  <value>hdfs://<namenode-host.company.com>:8020/var/log/hadoop-yarn/apps</value>
</property>
```

After specifying these directories in the yarn-site.xml file, you must create the directories and assign the correct file permissions to them on each node in your cluster.

``` ruby
# Create the yarn.nodemanager.local-dirs local directories:
sudo mkdir -p /data/1/yarn/local /data/2/yarn/local /data/3/yarn/local /data/4/yarn/local
# Create the yarn.nodemanager.log-dirs local directories:
sudo mkdir -p /data/1/yarn/logs /data/2/yarn/logs /data/3/yarn/logs /data/4/yarn/logs
# Configure the owner of the yarn.nodemanager.local-dirs directory to be the yarn user:
sudo chown -R yarn:yarn /data/1/yarn/local /data/2/yarn/local /data/3/yarn/local /data/4/yarn/local
# Configure the owner of the yarn.nodemanager.log-dirs directory to be the yarn user:
sudo chown -R yarn:yarn /data/1/yarn/logs /data/2/yarn/logs /data/3/yarn/logs /data/4/yarn/logs
```


Step 3: Configure the History Server




Step 4: Configure the Staging Directory

mapred-site.xml:

``` xml
<property>
    <name>yarn.app.mapreduce.am.staging-dir</name>
    <value>/user</value>
</property>
```

```
sudo -u hdfs hadoop fs -mkdir -p /user/history
sudo -u hdfs hadoop fs -chmod -R 1777 /user/history
sudo -u hdfs hadoop fs -chown mapred:hadoop /user/history
```

Step 5: If Necessary, Deploy your Custom Configuration to your Entire Cluster


Step 6: If Necessary, Start HDFS on Every Node in the Cluster


Step 7: If Necessary, Create the HDFS /tmp Directory


Step 8: Create the history Directory and Set Permissions and Owner



Step 9: Create Log Directories

```
sudo -u hdfs hadoop fs -mkdir -p /var/log/hadoop-yarn
sudo -u hdfs hadoop fs -chown yarn:mapred /var/log/hadoop-yarn
```

Step 10: Verify the HDFS File Structure

```
sudo -u hdfs hadoop fs -ls -R /

drwxrwxrwt   - hdfs supergroup          0 2012-04-19 14:31 /tmp
drwxr-xr-x   - hdfs supergroup          0 2012-05-31 10:26 /user
drwxrwxrwt   - mapred hadoop          0 2012-04-19 14:31 /user/history
drwxr-xr-x   - hdfs   supergroup        0 2012-05-31 15:31 /var
drwxr-xr-x   - hdfs   supergroup        0 2012-05-31 15:31 /var/log
drwxr-xr-x   - yarn   mapred            0 2012-05-31 15:31 /var/log/hadoop-yarn
```

Step 11: Start YARN and the MapReduce JobHistory Server

```
# On the ResourceManager system:
sudo service hadoop-yarn-resourcemanager start
# On each NodeManager system
sudo service hadoop-yarn-nodemanager start
# On the MapReduce JobHistory Server system
sudo service hadoop-mapreduce-historyserver start
```

Step 12: Create a Home Directory for each MapReduce User

Create a home directory for each MapReduce user. It is best to do this on the NameNode; for example:
```
sudo -u hdfs hadoop fs -mkdir  /user/<user>
sudo -u hdfs hadoop fs -chown <user> /user/<user>
```

Step 13: Configure the Hadoop Daemons to Start at Boot Time

``` ruby
# On the NameNode
sudo chkconfig hadoop-hdfs-namenode on

# On the ResourceManager
sudo chkconfig hadoop-yarn-resourcemanager on

# On the Secondary NameNode
sudo chkconfig hadoop-hdfs-secondarynamenode on

# On each NodeManager
sudo chkconfig hadoop-yarn-nodemanager on

# On each DataNode
sudo chkconfig hadoop-hdfs-datanode on

# On the MapReduce JobHistory node
sudo chkconfig hadoop-mapreduce-historyserver on
```



## Deploying CDH 5 Ecosystem Components

### Flume

### HBase

### Impala

### Hive

### Hue

### HttpFS

### KMS

### Oozie

### Pig

### Sentry

### Snappy

### Spark

### Sqoop

### Zookeeper

### Avro 
