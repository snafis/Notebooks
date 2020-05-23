# Troubleshooting Cloudera Installation and Upgrade Problems

**Table of Contents**


---


**Unable to connect to Cloudera Manager**

- Is the server running? Try running `service cloudera scm server status`
- If yes, try to access the web server locally "curl localhost:7180". If that works you've got a firewall problem. 
- Firewalls in ec2 can be a little tricky because there can be a firewall at the ec2 level and at the os level.
- If no, take a look at the server log at /var/log/cloudera scm server/cloudera scm server.log. 
- Any errors near then end of the log? If you don't see a log file, there should at least be a cloudera scm server.out file, try looking at that. 




**MySQL Troubleshooting**


Uninstall mysql using yum remove mysql*

Recursively delete /usr/bin/mysql and /var/lib/mysql

Delete the file /etc/my.cnf.rmp

Use ps -e to check the processes to make sure mysql isn't still running.

Reboot server with reboot

Run yum install mysql-server. This also seems to install the mysql client as a dependency.

Give mysql ownership and group priveleges with:

chown -R mysql /var/lib/mysql

chgrp -R mysql /var/lib/mysql

Use service mysqld start to start MySQL Daemon.


mysql_install_db --user=mysql --ldata=/var/lib/mysql/


BTW DO NOT TOUCH /var/lib/mysql/ibata1 !!!


wget http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo

sudo rm -Rf /usr/share/cmf /var/lib/cloudera* /var/cache/yum/cloudera*







The problem is caused by setting up the master on a running production server BEFORE doing the dump (as far as I can tell). So, there are queries written in the master_log that have already been executed on the data residing on the slave. I never actually saw a solution on the mysql website or mailing list. So, I came up with the following solution that solved my problem.

on slave:

mysql> STOP SLAVE;
mysql> FLUSH PRIVILEGES;  # dump likly included users too
on master:

mysql> RESET MASTER;
on slave:

mysql> RESET SLAVE;
mysql> START SLAVE;
by the way, I ran my dump with the following on the slave:

mysqldump -uROOTUSER -pROOTPASSWORD -hMYSQLMASTER.EXAMPLE.COM --all-databases --delete-master-logs | mysql -uROOTUSER -pROOTPASSWORD
I hope this helps someone else.

http://dev.mysql.com/doc/refman/5.0/en/reset-master.html

http://dev.mysql.com/doc/refman/5.0/en/reset-slave.html

tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
