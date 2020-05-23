<!--- 
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*
-->

# Installation Path B - Manual Installation Using Cloudera Manager Packages
The general steps in this procedure for Installation Path B are:

- [Installation Path B - Manual Installation Using Cloudera Manager Packages](#)
	- [Creating and Using a Local Package Repository](#creating-and-using-a-local-package-repository)
	- [Installing the Oracle JDK](#installing-the-oracle-jdk)
	- [Install Python 2.6 or 2.7](#install-python-2.6-or-2.7)
	- [Install the Cloudera Manager Server Packages](#install-the-cloudera-manager-server-packages)
	- [Set up a Database for the Cloudera Manager Server](#set-up-a-database-for-the-cloudera-manager-server)
	- [Install Cloudera Manager Agent Packages](#install-cloudera-manager-agent-packages)
	- [Install CDH and Managed Service Packages](#install-cdh-and-managed-service-packages)
	- [Start the Cloudera Manager Server](#start-the-cloudera-manager-server)
	- [Start and Log into the Cloudera Manager Admin Console](#start-and-log-into-the-cloudera-manager-admin-console)
	- [Choose Cloudera Manager Edition and Hosts](#choose-cloudera-manager-edition-and-hosts)
	- [Choose the Software Installation Method and Install Software](#choose-the-software-installation-method-and-install-software)
	- [Add Services](#add-services)
	- [Configure Cluster CDH Version for Package Installs](#configure-cluster-cdh-version-for-package-installs)
	- [Change the Default Administrator Password](#change-the-default-administrator-password)
	- [Test the Installation](#test-the-installation)


## Creating and Using a Local Package Repository
This section describes how to create a local package repository and then how to direct all the hosts in your environment to use that repository. 

To create a repository, you simply put the repo files you want to host in one directory. Then publish the resulting repository on a website:

* Installing Apache HTTPD
The repository is typically hosted using HTTP on a host inside your network. For this setup we will use Apache HTTPD.
``` ruby
[root@localhost yum.repos.d]$ yum install httpd
[root@localhost tmp]$  service httpd start
> Starting httpd:                                            [  OK  ]
```
* Download the tarball for your OS distribution from the repo as tarball archive. Unpack the tarball, move the files to the web server directory, and modify file permissions.

``` ruby
wget http://archive-primary.cloudera.com/cm5/repo-as-tarball/5.2.1/cm5.2.1-centos6.tar.gz
tar xvf cm5.2.1-centos6.tar 
mv cm /var/www/html
chmod -R ugo+rX /var/www/html/cm
```
After moving files and changing permissions, visit `http://hostname:port/cm` to verify that you see an index of files. Apache may have been configured to not show indexes, which is also acceptable.

* Modify Clients to Find Repository - Having established the repository, modify the clients so they find the repository.
Create files on client systems with the following information and format, where hostname is the name of the web server:
``` ruby
[myrepo]
name=myrepo
baseurl=http://hostname/cm/5
enabled=1
gpgcheck=0 
```
See `man yum.conf` for more details. Put that file into `/etc/yum.repos.d/myrepo.repo` on all of your hosts to enable them to find the packages that you are hosting.

Alternative, you can add the internet-accessible Cloudera repository by executing the following commands:

``` ruby
cd /etc/yum.repos.d/ 
wget http://archive.cloudera.com/cm5/redhat/5/x86_64/cm/cloudera-manager.repo
```

After completing these steps, you have established the environment necessary to install Cloudera Manager to hosts that are not connected to the Internet. 

## Installing the Oracle JDK

Install the Oracle Java Development Kit (JDK) on the Cloudera Manager Server host. The JDK is included in the Cloudera Manager 5 repositories. After downloading and editing the repo or list file, install the JDK as follows:

``` ruby
sudo yum install oracle-j2sdk1.7
```

## Install Python 2.6 or 2.7
If you are using Hue or installing CDH 5 using packages, Python 2.6 or 2.7 must be available or already installed. To ensure that it is installed, add the following to `/etc/yum.repos.d/epel.repo`:
``` ruby
[epel]
name=Local Mirror Extra Packages for Enterprise Linux 5 - x86_64
baseurl=http://mirror.infra.cloudera.com/epel/5/x86_64
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/cloudera-rpm-gpg/RPM-GPG-KEY-EPEL-5
failovermethod=priority
priority=20
```

## Install the Cloudera Manager Server Packages
Install the Cloudera Manager Server packages either on the host where the database is installed, or on a host that has access to the database. This host need not be a host in the cluster that you want to manage with Cloudera Manager. On the Cloudera Manager Server host, type the following commands to install the Cloudera Manager packages.

``` ruby
sudo yum install cloudera-manager-daemons cloudera-manager-server
```

## Set up a Database for the Cloudera Manager Server
Prepare a Cloudera Manager Server External Database.

``` ruby
# Install the MySQL database.
sudo yum install mysql-server
# Configuring and Starting the MySQL Server
sudo service mysqld stop
```

Determine the location of the option file, my.cnf.Update my.cnf so that it conforms to the following requirements:
``` ruby
[mysqld]
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
# symbolic-links = 0

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550

#log_bin should be on a disk with enough free space. Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your system and chown the specified folder to the mysql user.
#log_bin=/var/lib/mysql/mysql_binary_log
#expire_logs_days = 10
#max_binlog_size = 100M

# For MySQL version 5.1.8 or later. Comment out binlog_format for older versions.
binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```
Ensure the MySQL server starts at boot:

``` ruby
sudo /sbin/chkconfig mysqld on
sudo /sbin/chkconfig --list mysqld
> mysqld          0:off   1:off   2:on    3:on    4:on    5:on    6:off
```

Start the MySQL server:
``` ruby
sudo service mysqld start
```
Set the MySQL root password:
``` ruby
sudo /usr/bin/mysql_secure_installation
[...]
Enter current password for root (enter for none):
OK, successfully used password, moving on...
[...]
Set root password? [Y/n] y
New password:
Re-enter new password:
Remove anonymous users? [Y/n] Y
[...]
Disallow root login remotely? [Y/n] N
[...]
Remove test database and access to it [Y/n] Y
[...]
Reload privilege tables now? [Y/n] Y
All done!
```
Install the MySQL JDBC Driver:
``` ruby
# Download the MySQL JDBC driver from
wget http://www.mysql.com/downloads/connector/j/5.1.html.
# Extract the JDBC driver JAR file from the downloaded file. For example:
tar zxvf mysql-connector-java-5.1.31.tar.gz
# Copy the JDBC driver, renamed, to the relevant host. For example:
sudo cp mysql-connector-java-5.1.31/mysql-connector-java-5.1.31-bin.jar /usr/share/java/mysql-connector-java.jar
# If the target directory does not yet exist on this host, you can create it before copying the JAR file. For example:
sudo mkdir -p /usr/share/java/
sudo cp mysql-connector-java-5.1.31/mysql-connector-java-5.1.31-bin.jar /usr/share/java/mysql-connector-java.jar
```
Log into MySQL as the root user:
``` ruby
mysql -u root -p
Enter password:
> hadoop 20
```
Create databases for the Activity Monitor, Reports Manager, Hive Metastore Server, Sentry Server, Cloudera Navigator Audit Server, and Cloudera Navigator Metadata Server:
``` ruby
create database database DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on database.* TO 'user'@'%' IDENTIFIED BY 'password';
> Query OK, 0 rows affected (0.00 sec)
```
database, user, and password can be any value. The examples match the default names provided in the Cloudera Manager configuration settings:

| Role | Database | User | Password |
|------|----------|------|----------|
| Activity Monitor | amon | amon | amon_password |
| Reports Manager | rman | rman | rman_password |
| Hive Metastore Server | metastore | hive | hive_password |
| Sentry Server | sentry | sentry | sentry_password |
| Cloudera Navigator Audit Server | nav | nav | nav_password |
| Cloudera Navigator Metadata Server | navms | navms | navms_password |

Run the `scm_prepare_database.sh` script on the host where the Cloudera Manager Server package is installed:
``` ruby
/usr/share/cmf/schema/scm_prepare_database.sh
```

The script prepares the database by:
* Creating the Cloudera Manager Server database configuration file.
* Creating a database for the Cloudera Manager Server to use. This is optional and is only completed if options are specified.
* Setting up a user account for the Cloudera Manager Server. This is optional and is only completed if options are specified.

Example 1: Running the script when MySQL is installed on another host

This example explains how to run the script on the Cloudera Manager Server host (myhost2) and create and use a temporary MySQL user account to connect to MySQL remotely on the MySQL host (myhost1).

At the myhost1 MySQL prompt, create a temporary user who can connect from myhost2:
```
mysql> grant all on *.* to 'temp'@'%' identified by 'temp' with grant option;
> Query OK, 0 rows affected (0.00 sec)
```

On the Cloudera Manager Server host (myhost2), run the script:
```
sudo /usr/share/cmf/schema/scm_prepare_database.sh mysql -h 
> myhost1.sf.cloudera.com -utemp -ptemp --scm-host myhost2.sf.cloudera.com scm scm scm
> Looking for MySQL binary
> Looking for schema files in /usr/share/cmf/schema
> Verifying that we can write to /etc/cloudera-scm-server
> Creating SCM configuration file in /etc/cloudera-scm-server
> Executing: /usr/java/jdk1.6.0_31/bin/java -cp
> /usr/share/java/mysql-connector-java.jar:/usr/share/cmf/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor
> /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
> [ main] DbCommandExecutor INFO Successfully connected to database.
> All done, your SCM database is configured correctly!
```
On myhost1, delete the temporary user:
```
drop user 'temp'@'%';
> Query OK, 0 rows affected (0.00 sec)
```

> To Do: 
> [Configuring an External Database for Hue](http://www.cloudera.com/content/cloudera/en/documentation/core/v5-2-x/topics/cm_mc_hue_service.html#cmig_topic_15_unique_1)
> [Configuring an External Database for Oozie](http://www.cloudera.com/content/cloudera/en/documentation/core/v5-2-x/topics/cm_mc_oozie_service.html#cmig_topic_14_unique_1)


## Install Cloudera Manager Agent Packages
To install the packages manually, do the following on every Cloudera Manager Agent host (including those that will run one or more of the Cloudera Management Service roles: Service Monitor, Activity Monitor, Event Server, Alert Publisher, or Reports Manager):

``` ruby
sudo yum install cloudera-manager-agent cloudera-manager-daemons
```
On every Cloudera Manager Agent host, configure the Cloudera Manager Agent to point to the Cloudera Manager Server by setting the following properties in the `/etc/cloudera-scm-agent/config.ini` configuration file:

* server_host
* server_port

## Install CDH and Managed Service Packages

```
wget http://archive.cloudera.com/cdh5/one-click-install/redhat/6/x86_64/cloudera-cdh-5-0.x86_64.rpm
sudo yum --nogpgcheck localinstall cloudera-cdh-5-0.x86_64.rpm
sudo rpm --import http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
sudo yum clean all
sudo yum install avro-tools crunch flume-ng hadoop-hdfs-fuse hadoop-hdfs-nfs3 hadoop-httpfs hbase-solr hive-hbase hive-webhcat hue-beeswax hue-hbase hue-impala hue-pig hue-plugins hue-rdbms hue-search hue-spark hue-sqoop hue-zookeeper impala impala-shell kite llama mahout oozie pig pig-udf-datafu search sentry solr-mapreduce spark-python sqoop sqoop2 whirr
```
**Note:** Installing these packages also installs all the other CDH packages required for a full CDH 5 installation.

## Start the Cloudera Manager Server

```
sudo service cloudera-scm-server start
sudo service cloudera-scm-agent start
```

## Start and Log into the Cloudera Manager Admin Console

* The Cloudera Manager Server URL takes the following form `http://Server host:port`, where Server host is the fully-qualified domain name or IP address of the host where the Cloudera Manager Server is installed and port is the port configured for the Cloudera Manager Server. The default port is **7180**.

* In a web browser, enter http://Server host:7180, where Server host is the fully-qualified domain name or IP address of the host where the Cloudera Manager Server is running. The login screen for Cloudera Manager Admin Console displays.
Wait several minutes for the Cloudera Manager Server to complete its startup. To observe the startup process you can perform `tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log` on the Cloudera Manager Server host. 

* Log into Cloudera Manager Admin Console. The default credentials are: **Username:** `admin` **Password:** `admin`. Cloudera Manager does not support changing the admin username for the installed account. You can change the password using Cloudera Manager after you run the installation wizard. While you cannot change the admin username, you can add a new user, assign administrative privileges to the new user, and then delete the default admin account.

## Choose Cloudera Manager Edition and Hosts
You can use the Cloudera Manager wizard to choose which edition of Cloudera Manager you are using and which hosts will run CDH and managed services.

When you start the Cloudera Manager Admin Console, the install wizard starts up. Click Continue to get started.
Choose which edition to install:
Cloudera Express, which does not require a license, but provides a somewhat limited set of features.
Cloudera Enterprise Data Hub Edition Trial, which does not require a license, but expires after 60 days and cannot be renewed
Cloudera Enterprise with one of the following license types:
Basic Edition
Flex Edition
Data Hub Edition
If you choose Cloudera Express or Cloudera Enterprise Data Hub Edition Trial, you can elect to upgrade the license at a later time. See Managing Licenses.
If you have elected Cloudera Enterprise, install a license:
Click Upload License.
Click the document icon to the left of the Select a License File text field.
Navigate to the location of your license file, click the file, and click Open.
Click Upload.
Click Continue to proceed with the installation.
Click Continue in the next screen. The Specify Hosts page displays.
Do one of the following:
If you installed Cloudera Agent packages in Install Cloudera Manager Agent Packages, choose from among hosts with the packages installed:
Click the Currently Managed Hosts tab.
Choose the hosts to add to the cluster.
Search for and choose hosts:
To enable Cloudera Manager to automatically discover hosts on which to install CDH and managed services, enter the cluster hostnames or IP addresses. You can also specify hostname and IP address ranges. For example:
Range Definition	Matching Hosts
10.1.1.[1-4]	10.1.1.1, 10.1.1.2, 10.1.1.3, 10.1.1.4
host[1-3].company.com	host1.company.com, host2.company.com, host3.company.com
host[07-10].company.com	host07.company.com, host08.company.com, host09.company.com, host10.company.com
You can specify multiple addresses and address ranges by separating them by commas, semicolons, tabs, or blank spaces, or by placing them on separate lines. Use this technique to make more specific searches instead of searching overly wide ranges. The scan results will include all addresses scanned, but only scans that reach hosts running SSH will be selected for inclusion in your cluster by default. If you don't know the IP addresses of all of the hosts, you can enter an address range that spans over unused addresses and then deselect the hosts that do not exist (and are not discovered) later in this procedure. However, keep in mind that wider ranges will require more time to scan.

Click Search. Cloudera Manager identifies the hosts on your cluster to allow you to configure them for services. If there are a large number of hosts on your cluster, wait a few moments to allow them to be discovered and shown in the wizard. If the search is taking too long, you can stop the scan by clicking Abort Scan. To find additional hosts, click New Search, add the host names or IP addresses and click Search again. Cloudera Manager scans hosts by checking for network connectivity. If there are some hosts where you want to install services that are not shown in the list, make sure you have network connectivity between the Cloudera Manager Server host and those hosts. Common causes of loss of connectivity are firewalls and interference from SELinux.
Verify that the number of hosts shown matches the number of hosts where you want to install services. Deselect host entries that do not exist and deselect the hosts where you do not want to install services. Click Continue. The Select Repository screen displays.
Click Continue. The Select Repository page displays.

## Choose the Software Installation Method and Install Software
The following instructions describe how to use the Cloudera Manager wizard to install Cloudera Manager Agent, CDH, and managed service software.

Install CDH and managed service software using either packages or parcels:
Use Packages - If you did not install packages in Install CDH and Managed Service Packages, click the package versions to install. Otherwise, select the CDH version (CDH 4 or CDH 5) that matches the packages that you installed manually.
Use Parcels
Choose the parcels to install. The choices you see depend on the repositories you have chosen – a repository may contain multiple parcels. Only the parcels for the latest supported service versions are configured by default.
You can add additional parcels for previous versions by specifying custom repositories. For example, you can find the locations of the previous CDH 4 parcels at http://archive.cloudera.com/cdh4/parcels/. Or, if you are installing CDH 4.3 and want to use policy-file authorization, you can add the Sentry parcel using this mechanism.
To specify the parcel directory, local parcel repository, add a parcel repository, or specify the properties of a proxy server through which parcels are downloaded, click the More Options button and do one or more of the following:
Parcel Directory and Local Parcel Repository Path - Specify the location of parcels on cluster hosts and the Cloudera Manager Server host. If you change the default value for Parcel Directory and have already installed and started Cloudera Manager Agents, restart the Agents:
$ sudo service cloudera-scm-agent restart
Parcel Repository - In the Remote Parcel Repository URLs field, click the  button and enter the URL of the repository. The URL you specify is added to the list of repositories listed in the Configuring Cloudera Manager Server Parcel Settings page and a parcel is added to the list of parcels on the Select Repository page. If you have multiple repositories configured, you will see all the unique parcels contained in all your repositories.
Proxy Server - Specify the properties of a proxy server.
Click OK.
If you did not install Cloudera Manager Agent packages in Install Cloudera Manager Agent Packages, do the following:
Select the release of Cloudera Manager Agent to install. You can choose either the version that matches the Cloudera Manager Server you are currently using or specify a version in a custom repository. If you opted to use custom repositories for installation files, you can provide a GPG key URL that applies for all repositories. Click Continue. The JDK Installation Options screen displays.
Leave the Install Oracle Java SE Development Kit (JDK) checkbox selected to allow Cloudera Manager to install the JDK on each cluster host or deselect if you plan to install it yourself. If selected, your local laws permit you to deploy unlimited strength encryption, and you are running a secure cluster, select the Install Java Unlimited Strength Encryption Policy Files checkbox. Click Continue. The Provide SSH login credentials screen displays.
If you chose to have Cloudera Manager install packages, specify host installation properties:
Select root or enter the user name for an account that has password-less sudo permission.
Select an authentication method:
If you choose to use password authentication, enter and confirm the password.
If you choose to use public-key authentication provide a passphrase and path to the required key files.
You can choose to specify an alternate SSH port. The default value is 22.
You can specify the maximum number of host installations to run at once. The default value is 10.
Click Continue. If you did not install packages in (Optional) Install Cloudera Manager Agent, CDH, and Managed Service Software, Cloudera Manager installs the Oracle JDK, Cloudera Manager Agent, packages and CDH and managed service packages or parcels. During the parcel installation, progress is indicated for the phases of the parcel installation process in separate progress bars. If you are installing multiple parcels you will see progress bars for each parcel. When the Continue button at the bottom of the screen turns blue, the installation process is completed. Click Continue.
Click Continue. The Host Inspector runs to validate the installation, and provides a summary of what it finds, including all the versions of the installed components. If the validation is successful, click Finish. The Cluster Setup screen displays.

## Add Services
The following instructions describe how to use the Cloudera Manager wizard to configure and start CDH and managed services.

In the first page of the Add Services wizard you choose the combination of services to install and whether to install Cloudera Navigator:
Click the radio button next to the combination of services to install:

Core Hadoop - HDFS, YARN (includes MapReduce 2), ZooKeeper, Oozie, Hive, Hue, and Sqoop
Core with HBase
Core with Impala
Core with Search
Core with Spark
All Services - HDFS, YARN (includes MapReduce 2), ZooKeeper, Oozie, Hive, Hue, Sqoop, HBase, Impala, Solr, Spark, and Key-Value Store Indexer
Custom Services - Any combination of services.


As you select the services, keep the following in mind:
Some services depend on other services; for example, HBase requires HDFS and ZooKeeper. Cloudera Manager tracks dependencies and installs the correct combination of services.
In a Cloudera Manager deployment of a CDH 4 cluster, the MapReduce service is the default MapReduce computation framework. Choose Custom Services to install YARN or use the Add Service functionality to add YARN after installation completes.
  Note: You can create a YARN service in a CDH 4 cluster, but it is not considered production ready.
In a Cloudera Manager deployment of a CDH 5 cluster, the YARN service is the default MapReduce computation framework. Choose Custom Services to install MapReduce or use the Add Service functionality to add MapReduce after installation completes.
  Note: In CDH 5, the MapReduce service has been deprecated. However, the MapReduce service is fully supported for backward compatibility through the CDH 5 life cycle.
The Flume service can be added only after your cluster has been set up.
If you have chosen Data Hub Edition Trial or Cloudera Enterprise, optionally select the Include Cloudera Navigator checkbox to enable Cloudera Navigator. See the Cloudera Navigator Documentation.
Click Continue. The Customize Role Assignments screen displays.
Customize the assignment of role instances to hosts. The wizard evaluates the hardware configurations of the hosts to determine the best hosts for each role. The wizard assigns all worker roles to the same set of hosts to which the HDFS DataNode role is assigned. These assignments are typically acceptable, but you can reassign them if necessary.
Click a field below a role to display a dialog containing a list of hosts. If you click a field containing multiple hosts, you can also select All Hosts to assign the role to all hosts or Custom to display the pageable hosts dialog.

The following shortcuts for specifying hostname patterns are supported:
Range of hostnames (without the domain portion)
Range Definition	Matching Hosts
10.1.1.[1-4]	10.1.1.1, 10.1.1.2, 10.1.1.3, 10.1.1.4
host[1-3].company.com	host1.company.com, host2.company.com, host3.company.com
host[07-10].company.com	host07.company.com, host08.company.com, host09.company.com, host10.company.com
IP addresses
Rack name
Click the View By Host button for an overview of the role assignment by hostname ranges.

When you are satisfied with the assignments, click Continue. The Database Setup screen displays.
On the Database Setup page, configure settings for required databases:
Enter the database host, database type, database name, username, and password for the database that you created when you set up the database.
Click Test Connection to confirm that Cloudera Manager can communicate with the database using the information you have supplied. If the test succeeds in all cases, click Continue; otherwise check and correct the information you have provided for the database and then try the test again. (For some servers, if you are using the embedded database, you will see a message saying the database will be created at a later step in the installation process.) The Review Changes screen displays.
Review the configuration changes to be applied. Confirm the settings entered for file system paths. The file paths required vary based on the services to be installed.
  Warning: DataNode data directories should not be placed on NAS devices.
Click Continue. The wizard starts the services.
When all of the services are started, click Continue. You will see a success message indicating that your cluster has been successfully started.
Click Finish to proceed to the Home Page.

## Configure Cluster CDH Version for Package Installs
If you have installed CDH as a package, after an install or upgrade, make sure that the cluster CDH version matches the package CDH version, using the procedure in Configuring the CDH Version of a Cluster. If the cluster CDH version does not match the package CDH version, Cloudera Manager incorrectly enables and disables service features based on the cluster's configured CDH version.

## Change the Default Administrator Password
As soon as possible after running the wizard and beginning to use Cloudera Manager, change the default administrator password:
Right-click the logged-in username at the far right of the top navigation bar and select Change Password.
Enter the current password and a new password twice, and then click Update.

## Test the Installation
You can test the installation following the instructions in Testing the Installation.









