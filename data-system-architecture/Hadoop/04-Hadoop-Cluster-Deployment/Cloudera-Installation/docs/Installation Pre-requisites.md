# Cloudera Distribution Hadoop (CDH) Installation Pre-requisities

## Cluster Hardware

### Disks

* Dedicate disk [0,1] (RAID 1) for OS and logs
* Disks [2-n] in a JBOD configuration with individually mounted ext4 partitions on systems running RHEL6+
* Use EXT3/EXT4/XFS format and mount with `noatime` option. Do not use LVM


``` ruby
# creating linux partitions
su -
fdisk /dev/sdb
ls /dev/sd*
# creating a new filesystem
mkfs.ext4 -L /data /dev/sdb
# mouting a filesystem
mkdir /data
mount /dev/sdb /data -o noatime
mount
# Configuring RHEL 6 to Automatically Mount a Filesystem
vi /etc/fstab
> Add entry like below
> Partition/Label Name       MountPoint          Filesystemtype           defaults      0 0
> eg: /dev/sda4               /mnt/new                ext3                defaults      0 0
> :wq!  Save the file
mount -a
# Verify that the controller firmware is up to date and check for potential disk errors
dmesg | egrep -i 'sense error'
dmesg | egrep -i 'ata bus error'
# test disk i/o speed
hdparm -t /dev/sdb
# check disk bad sectors
badblocks -v /dev/sdb
```


``` bash
# Set noatime on DN volumes
sudo mount -o remount -o noatime /
cat /proc/mounts
> rootfs / rootfs rw 0 0
> proc /proc proc rw,relatime 0 0
> sysfs /sys sysfs rw,relatime 0 0
> devtmpfs /dev devtmpfs rw,relatime,size=3730672k,nr_inodes=932668,mode=755 0 0
> devpts /dev/pts devpts rw,relatime,gid=5,mode=620,ptmxmode=000 0 0
> tmpfs /dev/shm tmpfs rw,relatime 0 0
> /dev/xvda1 / ext4 rw,noatime,barrier=1,data=ordered 0 0
> /proc/bus/usb /proc/bus/usb usbfs rw,relatime 0 0
> none /proc/sys/fs/binfmt_misc binfmt_misc rw,relatime 0 0
> /etc/auto.misc /misc autofs rw,relatime,fd=7,pgrp=949,timeout=300,minproto=5,maxproto=5,indirect 0 0
> -hosts /net autofs rw,relatime,fd=13,pgrp=949,timeout=300,minproto=5,maxproto=5,indirect 0 0

cat /etc/fstab
> #
> # /etc/fstab
> # Created by anaconda on Mon Sep 29 08:58:10 2014
> #
> # Accessible filesystems, by reference, are maintained under '/dev/disk'
> # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
> #
> UUID=9996863e-b964-47d3-a33b-3920974fdbd9 /                       ext4    defaults,noatime        1 1
> tmpfs                   /dev/shm                tmpfs   defaults        0 0
> devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
> sysfs                   /sys                    sysfs   defaults        0 0
> proc                    /proc                   proc    defaults        0 0

# Set reserve space for root on DN volumes to 0
fdisk -l
> Disk /dev/xvda1: 32.2 GB, 32212254720 bytes
> 255 heads, 63 sectors/track, 3916 cylinders
> Units = cylinders of 16065 * 512 = 8225280 bytes
> Sector size (logical/physical): 512 bytes / 512 bytes
> I/O size (minimum/optimal): 512 bytes / 512 bytes
> Disk identifier: 0x00000000

tune2fs -m 0 /dev/xvda1
> tune2fs 1.41.12 (17-May-2010)
> Setting reserved blocks percentage to 0% (0 blocks)

# Check the user resource limits for max file descriptors and processes

echo  hdfs    -  nofile  32768  >>  /etc/security/limits.conf
echo  mapred  -  nofile  32768  >>  /etc/security/limits.conf
echo  hdfs    -  nproc   32768  >>  /etc/security/limits.conf
echo  mapred  -  nproc   32768  >>  /etc/security/limits.conf


# Test forward and reverse lookups for both file-based and DNS name services a. Note: /etc/hosts, the FQDN must be listed first
b. Note: 127.0.0.1 must resolve to localhost
[root@ip-172-31-41-143 .ssh]# hostname --fqdn
ip-172-31-41-143.eu-west-1.compute.internal
[root@ip-172-31-41-143 .ssh]# host 'ip-172-31-41-143.eu-west-1.compute.internal'
ip-172-31-41-143.eu-west-1.compute.internal has address 172.31.41.143
[root@ip-172-31-41-143 .ssh]# host 172.31.41.143
143.41.31.172.in-addr.arpa domain name pointer ip-172-31-41-143.eu-west-1.compute.internal.


# Enable nscd

[root@ip-172-31-41-143 .ssh]#sudo yum install nscd
[root@ip-172-31-41-143 .ssh]#vi /etc/nscd.conf
# make sure only hosts and services are 'yes'
enable-cache hosts yes
enable-cache services yes
enable-cache passwd no
enable-cache group no
enable-cache netgroup no

[root@ip-172-31-41-143 .ssh]#service nscd start
[root@ip-172-31-41-143 .ssh]#chkconfig nscd on
```

## Operating System

### OS Version
Ensure that a supported OS is in use.

``` ruby
cat /etc/redhat-release
```

### Swappiness

For kernel version earlier than 2.6.32-303 [`uname -r`], set `vm.swappiness=0`. Otherwise, set it to 1.

``` ruby
sudo su root
echo "vm.swappiness = 1" >> /etc/sysctl.conf
echo 1 > /proc/sys/vm/swappiness
```

### Date Synchronization & NTP
``` ruby
sudo yum install ntp
chkconfig ntpd on
date
grep server /etc/ntp.conf
service ntpd start
ntpq -p
```


### Firewalls

Disable all firewall software on and between the cluster hosts

``` ruby
service iptables stop
service ip6tables stop
/sbin/chkconfig --list iptables
/sbin/chkconfig --list ip6tables
/sbin/chkconfig iptables off
/sbin/chkconfig ip6tables off

# retsrt network services
/etc/init.d/network restart
```

### Kernel Security Modules

Disable SELinux

Edit `/etc/sysconfig/selinux` to set `SELINUX=disabled`

``` ruby
selinuxenabled || echo "disabled"
sudo vi /etc/sysconfig/selinux
# set SELINUX=disabled
```
alternatively,
``` ruby
perl -p -i -e "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
```

> Note: a system reboot is required in order for the SELinux changes to take effect.

``` ruby
# restart the network services and reboot the server
/etc/init.d/network restart
init 6
```

#### Add Groups and Users
``` ruby
groupadd hadoop
useradd hduser -g hadoop
usermod -aG wheel hduser
perl -p -i -e "s/\# \%wheel/\%wheel/g" /etc/sudoers
passwd hduser
#hadoop20
```

#### Enable Password Authentication

``` ruby
perl -p -i -e "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
```

#### Secure Shell

Ensure that the secure shell daemon (sshd) is running:

``` ruby
service sshd status
service sshd start
```

Modify the ssh configuration file `/etc/ssh/ssh_config`, Uncomment the following line and change the value to no; this will prevent the question when connecting with SSH to the host.

``` ruby
StrictHostKeyChecking no
```

Enable passwordless SSH connectivity between the hosts:

``` ruby
# login as hduser
sudo su hduser
# generate your server key
ssh-keygen
#press "Enter" three times
cat /home/hduser/.ssh/id_rsa.pub
#copy and paste it into a text file for future
```

Configure "authorized_keys" file in all of the instances

``` ruby
# on Cloudera1 instance
cd /home/hduser/.ssh
vi authorized_keys
#go to the end of file by "ESC->o"
#copy/paste all the public rsa keys to the end of file
#save and exit file by "ESC->wq!"
#do the same on all the other instances
```
Test ssh connectivity
``` ruby
ssh hduser@ec2-52-17-249-61.eu-west-1.compute.amazonaws.com
ssh hduser@ec2-52-17-211-71.eu-west-1.compute.amazonaws.com
ssh hduser@ec2-52-17-214-162.eu-west-1.compute.amazonaws.com
ssh hduser@ec2-52-17-234-3.eu-west-1.compute.amazonaws.com
```

### User Limits (*ulimits*)

``` ruby
#
echo hdfs - nofile 32768 >> /etc/security/limits.conf
echo mapred - nofile 32768 >> /etc/security/limits.conf
echo hbase - nofile 32768 >> /etc/security/limits.conf
#
echo hdfs - nproc 32768 >> /etc/security/limits.conf
echo mapred - nproc 32768 >> /etc/security/limits.conf
echo hbase - nproc 32768 >> /etc/security/limits.conf

```

### Transparent Huge Pages

``` ruby
echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
# **Remember to add this to your /etc/rc.local file to make it reboot persistent.**
```

### Java

Install the Oracle Java Development Kit (JDK) on the Cloudera Manager Server host. The JDK is included in the Cloudera Manager 5 repositories. After downloading and editing the repo or list file, install the JDK as follows:

``` ruby
java -version
javac -version
update-java-alternatives --list
alternatives --display java
sudo yum install oracle-j2sdk1.7
```

### Python

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

```
python -V
> Python 2.6.6
```


## Network

### Hostnames

Ensure that hostname is set to the fully qualified domain name (FQDN).

``` ruby
grep HOSTNAME /etc/sysconfig/network
# if it is not the fully qualified domain name, do the following
perl -p -i -e "s/localhost.localadmin/${hostname}/g" /etc/sysconfig/network
```

### DNS

Ensure that both forward and reverse lookup are functional.

For that, make your own reference table for public DNS

``` ruby
| machine name| public DNS                                       |
| ------------|:------------------------------------------------:|
| cdh1        |ec2-52-17-66-115.eu-west-1.compute.amazonaws.com  |
| cdh2        |ec2-52-16-198-107.eu-west-1.compute.amazonaws.com |
| cdh3        |ec2-52-17-43-87.eu-west-1.compute.amazonaws.com   |
```

Use the following commands:

``` ruby
$ host `hostname`
bp101.cloudera.com has address 10.20.195.121
$ host 10.20.195.121
121.195.20.10.in-addr.arpa domain name pointer bp101.cloudera.com
```

### IPv6

Ensure that IPv6 is disabled.

Add the following lines at the end of the `/etc/sysctl.conf` file.


``` ruby
# disable ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.io.disable_ipv6 = 1

```

Add the following to `/etc/sysconfig/network` file.

``` ruby
NETWORKING_IPV6=no
IPV6INIT=no
```




## Databases

Cloudera Manager uses databases to store information about the Cloudera Manager configuration, as well as information such as the health of the system or task progress. Cloudera Manager supports using a variety of databases to store required information. To facilitate rapid completion of simple installations, the Cloudera Manager can install and configure a PostgreSQL database as part of the broader Cloudera Manager installation process. This automatically installed database is sometimes referred to as an embedded PostgreSQL database. While the embedded database is a useful option for getting started quickly, Cloudera Manager also allows you to use other databases. You can opt to use your own PostgreSQL database or MySQL or Oracle databases.

### Installing and Configuring a MySQL Database
``` ruby
# install mysql server
sudo yum install mysql-server

# start mysql daemon
sudo service mysqld start

# configure mysqld to startup automatically following reboot
chkconfig mysqld on
chkconfig --list mysqld
> mysqld          0:off   1:off   2:on    3:on    4:on    5:on    6:off

# install mysql JDBC connector
sudo yum install mysql-connector-java

# secure mysql install
sudo /usr/bin/mysql_secure_installation
> [...]
> Enter current password for root (enter for none):
> OK, successfully used password, moving on...
> [...]
> Set root password? [Y/n] y
> New password:
> Re-enter new password:
> Remove anonymous users? [Y/n] Y
> [...]
> Disallow root login remotely? [Y/n] N
> [...]
> Remove test database and access to it [Y/n] Y
> [...]
> Reload privilege tables now? [Y/n] Y
> All done!

# Log into MySQL as the root user
mysql -u root -p
> Enter password: (use password 'hadoop20')

# create databases to support cloudera manager and hadoop ecosystem components

# create a database for the Activity Monitor.
create database amon DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on amon.* TO 'amon'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for the Service Monitor
create database smon DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on smon.* TO 'smon'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for the Report Monitor
create database rman DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on rman.* TO 'rman'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for the Host Monitor
create database hmon DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on hmon.* TO 'hmon'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 0 rows affected (0.00 sec)


# create a database for the Hive metastore
create database metastore DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on metastore.* TO 'metastore'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for Cloudera Navigator
create database nav DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on nav.* TO 'nav'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for Sentry
create database sentry DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on sentry.* TO 'sentry'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for Oozie
create database ooze_server DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on ooze_server.* TO 'oozie_server'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

# create a database for Hue
create database hue DEFAULT CHARACTER SET utf8;
> Query OK, 1 row affected (0.00 sec)
grant all on hue.* TO 'hue'@'%' IDENTIFIED BY 'hadoop20';
> Query OK, 1 row affected (0.00 sec)

FLUSH PRIVILEGES;

```

In addition, recommended MySQL configurations settings are as follows. You should incorporate these changes as appropriate into your configuration settings.

``` ruby
[client]
port = 3306
socket = /var/lib/mysql/mysql.sock

[mysqld]
port = 3306
socket = /var/lib/mysql/mysql.sock
skip-external-locking
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
# symbolic-links = 0

[mysqld]
key_buffer = 16M
key_buffer_size = 64M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 16M
query_cache_size = 64M
query_cache_type = 1
max_connections = 700
table_open_cache = 256
sort_buffer_size = 8M
join_buffer_size = 8M
net_buffer_length = 8K
read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M
thread_concurrency = 8
server-id = 1		# replication ID (Master is 1)
bind_address = 172.31.41.143
log_bin=/var/lib/mysql/mysql_binary_log # for replication
expire_logs_days = 10
max_binlog_size = 100M
binlog_format = mixed

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 1 # supports replication
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 2G
innodb_thread_concurrency = 16
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M
sync_binlog = 1		# supports replication

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
datadir=/var/lib/mysql
# user=mysql

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 128M
sort_buffer_size = 128M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
```

### MySQL Replication Setup

> ToDo: Tidy up this section later on. 

* On the MASTER NODE option file `my.cnf` configure the following parameters:

``` mysql
bind_address = w.x.y.z
server_id = 1
```

* Create a user for replication:

``` mysql
mysql> create user 'repl'@'ip-172-31-41-144.eu-west-1.compute.internal' identified by 'salvepassword';
mysql> grant replication slave on *.* to 'repl'@'ip-172-31-41-144.eu-west-1.compute.internal';
mysql> grant ALL PRIVILEGES ON *.* to 'repl'@'ip-172-31-41-144.eu-west-1.compute.internal';
```

* For testing create a dummy database:table

```
mysql> create database pets;
mysql> create table pets.cats (name varchar(20));
mysql> insert into pets.cats values ('fluffy');
mysql> select * from pets.cats;
```

* Dump a copy of the database and copy this file across to the backup server:

```
mysqldump -uroot --all-databases --master-data > masterdump.sql
grep CHANGE *sql | head -l
scp masterdump.sql db_host_2_ip
```

* Install MySQL on the backup server

```
sudo yum install mysql mysql-server
sudo yum install mysql-connector-java
```
* Configure MASTER NODE INFO on the SLAVE NODE:

```
CHANGE MASTER TO
MASTER_HOST='ip-172-31-41-143.eu-west-1.compute.internal',
MASTER_USER='repl',
MASTER_PASSWORD='slavepassword';
```

* Import musql dump into the backup node

```
mysql -uroot < masterdump.sql
```

* Start the SLAVE and check for its status:

```
start slave
show slave status\G;

*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: ip-172-31-41-143.eu-west-1.compute.internal
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql_binary_log.000001
          Read_Master_Log_Pos: 106
               Relay_Log_File: mysqld-relay-bin.000002
                Relay_Log_Pos: 258
        Relay_Master_Log_File: mysql_binary_log.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 106
              Relay_Log_Space: 414
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
1 row in set (0.00 sec)
```
* Insert a new entry in the MASTER NODE and see it appear in the SLAVE NODE

```
mysql> insert into pets.cats values ("bigfoot");
mysql> select * from pets.cats;
```


## CDH Repository

### Setting up a local yum repository for CDK and CM

To set up your own internal mirror, follow the steps below. You need an internet connection for the steps that require you to download packages and create the repository itself. You will also need an internet connection in order to download updated RPMs to your local repository.

``` ruby
# Navigate to the repos directory and download the cloudera repo file there.
cd /etc/yum.repos.d/
sudo wget http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
sudo wget http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo


# For reference, the repo like looks like this:
> [cloudera-cdh5]
> # Packages for Cloudera's Distribution for Hadoop, Version 5, on RedHat	or CentOS 6 x86_64
> name=Cloudera's Distribution for Hadoop, Version 5
> baseurl=http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/5/
> gpgkey = http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
> gpgcheck = 1

# Install a web server such as apache/lighttpd on the machine which will serve the RPMs.

> **Note:** The default configuration should work. HTTP access must be allowed to pass through any firewalls between this server and the internet connection.

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

# On the server with the web server,, install the yum-utils and createrepo RPM packages if they are not already installed.
The yum-utils package includes the reposync command, which is required to create the local Yum repository.

sudo yum install yum-utils createrepo


# On the same computer as in the previous steps, download the yum repository into a temporary location
reposync -r cloudera-cdh5


# Put all the RPMs into a directory served by your web server

Such as /var/www/html/cdh/5/RPMS/noarch/ (or x86_64 or i386 instead of noarch). The directory structure 5/RPMS/noarch is required. Make sure you can remotely access the files in the directory via HTTP, using a URL similar to http://<yourwebserver>/cdh/5/RPMS/).

# On your web server, issue the following command from the 5/ subdirectory of your RPM directory:
createrepo .

# Edit the repo file you downloaded in step 1. replace the line starting with baseurl= or mirrorlist= with baseurl=http://<yourwebserver>/cdh/5/, using the URL from step 5. Save the file back to /etc/yum.repos.d/.


# While disconnected from the internet, issue the following commands to install CDH from your local yum repository.
yum clean all
yum update
yum install hadoop

# Once you have confirmed that your internal mirror works, you can distribute this modified repo file to any system which can connect to your repository server. Those systems can now install CDH from your local repository without internet access.

yum clean all
yum update


# Optionally Add a Repository Key
sudo rpm --import http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera
```



## Security

> To DO
