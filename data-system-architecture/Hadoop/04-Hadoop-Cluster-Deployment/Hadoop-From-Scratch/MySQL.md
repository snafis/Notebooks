## Mac OS X MySQL Install

Adding MySQL on my MacBook development environment has been on my list for a while but it finally made the top.

We will start off by downloading the MySQL binaries from their [website](http://dev.mysql.com/downloads/mysql/). For reference, I am using **MySQL Server Community Edition 5.6.17**.  

### Step-1: Install MySQL Server

Once the download is completed, Launch the MySQL installer pkg file first (`mysql-5.6.17-osx10.9-x86_64.tar.gz`)and follow the on-screen instructions to complete the installation. 

Couple of points to note: While you can change the installation location, by default its in the `/usr/local/mysql` directory. The installation requires that you have a mysql user account on the operating system, and you don’t need to do anything because one exists as part of the default Mac OS X installation. 

### Step-2: Install MySQL Startup Item

The next step is to install the `MySQLStartupItem.pkg` file. As before, complete the installation by accepting all the default settings.

### Step-3: Install MySQL Preference Pane 

This step requires that you return to the download folder and launch the `MySQL.prefPane`. As before, complete the installation by accepting all the default settings.

### Step-4: Shell Configurations

Don’t click in the automatic start button just yet. Otherwise, there is going to be a lot of cleanup to be able to return to this point.

First of all, let's check the permissions on `/Library/StartupItems/MySQLCOM`:

```bash
cd /Library/StartupItems/MySQLCOM
ls -al
```
If you see these permissions, you have problem because the group for startup files should be wheel not staff:
```
drwxr-xr-x  4 root  staff   136 Jan 20 13:46 .
drwxr-xr-x  4 root  wheel   136 Feb  9 21:11 ..
-rwxr-xr-x  1 root  staff  1300 Jan 20 13:46 MySQLCOM
-rw-r--r--  1 root  staff   469 Jan 20 13:46 StartupParameters.plist
```

You can change the files with this command:
```bash
cd ..
sudo chown root:wheel MySQLCOM
```

Next up is configuring the shell environment and harden the database. Hardening means securing accounts with passwords. They’re covered in the next two sections.

##### Configure User’s Shell Environment

Append the `~/.bashrc_local` with the following configurations.

``` bash
# Set the MySQL Home environment variable to point to the root directory of the MySQL installation.
export set MYSQL_HOME=/usr/local/mysql-5.6.17-osx10.9-x86_64

# Add the /bin directory from the MYSQL_HOME location into your $PATH environment variable.
export set PATH=$PATH:$MYSQL_HOME/bin

# Create aliases that make it easier for you to manually start and stop the MySQL Daemon.
alias mysqlstart="sudo /Library/StartupItems/MySQLCOM/MySQLCOM start"
alias mysqlstop="sudo /Library/StartupItems/MySQLCOM/MySQLCOM stop"
alias mysqlstatus="ps aux | grep mysql | grep -v grep"
```

As pointed out by Shashank’s comment, you should now use the following aliases:

alias mysqlstart='sudo /usr/local/mysql/support-files/mysql.server start'
alias mysqlstop='sudo /usr/local/mysql/support-files/mysql.server stop'


##### Secure the Database

This is presently necessary because of the different file structure in a Mac OS X MySQL install, which disables the mysql_secure_installation file from running successfully. You can manually edit the file or follow these steps.

You need to connect to the database as the privileged super user, root user. This is simple because the installation doesn’t set any passwords. You open anotherTerminal session to make these changes or you could install MyPHPAdmin orMySQL Workbench. The tools work as well in fixing the majority of issues.

Once connected to the database as the root user, you can confirm that passwords aren’t set and an insecure anonymous user account has been previously configured. You do that by connecting to the mysql database, which is the database catalog for MySQL. You do that by running the following command:

You can query the result set with the following query:

```sql
SELECT USER, password, host FROM USER\G
You should see the following output plus the user’s name preceding the MacPro(or iMac.local) host name value:


*************************** 1. row ***************************
    user: root
password: 
    host: localhost
*************************** 2. row ***************************
    user: root
password: 
    host: MacPro.local
*************************** 3. row ***************************
    user: root
password: 
    host: 127.0.0.1
*************************** 4. row ***************************
    user: root
password: 
    host: ::1
*************************** 5. row ***************************
    user: 
password: 
    host: localhost
*************************** 6. row ***************************
    user: 
password: 
    host: MacPro.local
```

You now need to change the password for the root user. I would suggest that you do this with the SQL command rather than a direct update against the data dictionary tables. The syntax to fix the root user account require you enter the user name, an @ symbol, and complete host values, like:

```sql
SET PASSWORD FOR 'root'@'localhost' = password('cangetin');
SET PASSWORD FOR 'root'@'MacPro.local' = password('cangetin');
SET PASSWORD FOR 'root'@'127.0.0.1' = password('cangetin');
SET PASSWORD FOR 'root'@'::1' = password('cangetin');
```
You should be able to drop both anonymous user rows with the following syntax, but I did encounter a problem. Assuming you may likewise encounter the problem, the fix follows the first commands you should try:


DROP USER ''@'localhost';
DROP USER ''@'MacPro.local';
If either of the anonymous accounts remain in the USER table, you can manually drop them from the database catalog. This syntax will get rid of them:


DELETE FROM USER WHERE LENGTH(USER) = 0;
You’ve completed the configuration and can now type quit; to exit the MySQL Monitor. To reconnect, you’ll now need a password, like this:

Also, don’t forget to use a real password. The one shown here is trivial, which means easy to hack. Use something that others might not guess.

##### Configure my.cnf file

You can copy one of the sample configuration files as a starting point (as provided by Don McArthur’s comment):

```
sudo cp /usr/local/mysql/support-files/my-huge.cnf /etc/my.cnf
```


##### Starting and Stopping the Database
Start MySQL from Mac System Preference or simply typing `mysqlstart` from an open terminal.
Stopping it is also straightforward, you do this: `mysqlstop`
You can check it’s status with this command: `mysqlstatus`
