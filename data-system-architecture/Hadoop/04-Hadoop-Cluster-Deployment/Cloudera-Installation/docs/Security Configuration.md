# Security Configuration

## Hadoop Security Setup Pre-requisite

* working hadoop cluster
* working Kerberos KDC server
* kerberos client libraries installed on all Hadoop nodes

### Install Kerberos Key Distribution Centre

The KDC server can be a completely separate machine or for example the machine where Cloudera Manager is running. 
To install the KDC server I followed the steps describe on the CentOS website: [Configure a Kerberos 5 server](https://www.centos.org/docs/5/html/5.1/Deployment_Guide/s1-kerberos-server.html).

> **NOTE:** These commands need to be performed on the machine which will act as the KDC. All these command need to be preformed as **root** or as a user with **sudo** rights.

#### 1. Install the krb5-libs, krb5-server, and krb5-workstation packages

```
sudo yum install krb5-server krb5-libs krb5-auth-dialog
```

#### 2. Set the realm name and the domain-to-realm mapping in `/etc/krb5.conf` and `/var/kerberos/krb5dc/kdc.conf`

> **NOTE:** By convention, all realm names are uppercase and all DNS hostnames and domain names are lowercase.

Our KDC is running on `utilityhost.company.com` and out realm is `HADOOP.COMPANY.COM`. 

Here is the content of the `/etc/krb5.conf` file:

``` bash
# /etc/krb5.conf

[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = HADOOP.COMPANY.COM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 1d 0h 0m 0s
 renew_lifetime = 7d 0h 0m 0s
 forwardable = true

[realms]
 HADOOP.COMPANY.COM = {
  kdc = hutilityhost.company.com
  admin_server = utilityhost.company.com
  default_domain = company.com
 }

[domain_realm]
 .example.com = HADOOP.COMPANY.COM
 example.com = HADOOP.COMPANY.COM
```

The content of `/var/kerberos/krb5kdc/kdc.conf`:

``` bash
# /var/kerberos/krb5kdc/kdc.conf 

[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 HADOOP.COMPANY.COM = {
  master_key_type = aes256-cts
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal
  max_life = 1d 0h 0m 0s
  max_renewable_life = 7d 0h 0m 0s
 }
```

> **NOTE:** we added the **max_life** and **max_renewable_life** properties.

#### 3. Create the database which stores the keys for the Kerberos realm

Running `kdb5_util` with `-s` will create the stash file in which we store the master password. Without this file the KDC will prompt the user for the master password every time that it starts.

``` bash
kdb5_util create -s
> Loading random data
> Initializing database '/var/kerberos/krb5kdc/principal' for realm 'HADOOP.COMPANY.COM',
> master key name 'K/M@HADOOP.COMPANY.COM'
> You will be prompted for the database Master Password.
> It is important that you NOT FORGET this password.
> Enter KDC database master key: 'shifathcdh'
> Re-enter KDC database master key to verify: 'shifathcdh'
```

#### 4. Edit the `/var/kerberos/krb5kdc/kadm5.acl` file 

This file is used by kadmind to determine which principals have administrative access to the Kerberos database and their level of access. Most organizations can get by with a single line:

``` bash
# /var/kerberos/krb5kdc/kadm5.acl 
*/admin@HADOOP.COMPANY.COM  *
```

#### 5. Create your first principal

First you should create a principal which has administrator privileges (the pricipal has to match the expression that you specified in `/var/kerberos/krb5kdc/kadm5.acl`). The `kadmin` utility communicates with the `kadmind` server over the network, and uses Kerberos to handle authentication. The first principal must already exist before connecting to the server over the network. We can create this principal with `kadmin.local`.

``` bash
kadmin.local -q "addprinc hduser/admin"
> Authenticating as principal root/admin@HADOOP.COMPANY.COM with password.
> WARNING: no policy specified for tunde/admin@HADOOP.COMPANY.COM; defaulting to no policy
> Enter password for principal "hduser/admin@HADOOP.COMPANY.COM": 'hduser'
> Re-enter password for principal "hduser/admin@HADOOP.COMPANY.COM": 'hduser'
> Principal "hduser/admin@HADOOP.COMPANY.COM" created.
```

#### 6. Start Kerberos and make sure that the services will start after reboot

``` bash
sudo service krb5kdc start
sudo service kadmin start
sudo chkconfig krb5kdc on
sudo chkconfig kadmin on
```

#### 7. Add principals 

Add principals for the users using the `addprinc` command within `kadmin`. `kadmin` and `kadmin.local` are command line interfaces to the KDC. As such, many commands — such as addprinc — are available after launching the kadmin program. Refer to the kadmin man page for more information.

As root you can use kadmin.local, but you cannot use kadmin because we didn't add a principal root/admin@GDD.NL. So this is what would happen:

``` bash
# log in with the root/admin principal -- fails, because we did not add this principal
kadmin
> Authenticating as principal root/admin@HADOOP.COMPANY.COM with password.
> kadmin: Client not found in Kerberos database while initializing kadmin interface

# log in with the hduser/admin principal -- works
kadmin -p hduser/admin
> Authenticating as principal hduser/admin with password.
> Password for hduser/admin@HADOOP.COMPANY.COM: 'hduser'
> kadmin:
> kadmin: exit

# log in with kadmin.local as root -- works
kadmin.local
> Authenticating as principal root/admin@HADOOP.COMPANY.COM with password.
> kadmin.local: 
> kadmin.local: exit
```

So let's see how we manage principals:

```
kadmin -p hduser/admin
Authenticating as principal hduser/admin with password.
Password for hduser/admin@HADOOP.COMPANY.COM:

#list principals -- see which users can get a kerberos ticket
kadmin: list_principals

#add a new principal
kadmin:  addprinc user1
    WARNING: no policy specified for user1@HADOOP.COMPANY.COM; defaulting to no policy
    Enter password for principal "user1@HADOOP.COMPANY.COM": 
    Re-enter password for principal "user1@HADOOP.COMPANY.COM": 
    Principal "user1@HADOOP.COMPANY.COM" created.

#delete principal
kadmin: delprinc user1
    Are you sure you want to delete the principal "user1@HADOOP.COMPANY.COM"? (yes/no): yes
    Principal "user1@HADOOP.COMPANY.COM" deleted.
    Make sure that you have removed this principal from all ACLs before reusing.

#let's add the user1 principal back
kadmin:  addprinc user1
    WARNING: no policy specified for user1@HADOOP.COMPANY.COM; defaulting to no policy
    Enter password for principal "user1@HADOOP.COMPANY.COM": 
    Re-enter password for principal "user1@HADOOP.COMPANY.COM": 
    Principal "user1@HADOOP.COMPANY.COM" created.

kadmin: exit
```

Alternatively, you can also perform the following from the console.

```
kadmin -p hduser/admin -q "list_principals"
kadmin -p hduser/admin -q "addprinc user2"
kadmin -p hduser/admin -q "delprinc user2"
```

> NOTE: The principal username and the principal username/admin are different. If you added a principal username/admin that doesn't mean that you can get a ticket for the principal username.

``` bash
kinit hduser
    kinit: Client not found in Kerberos database while getting initial credentials
kinit hduser/admin
    Password for hduser/admin@HADOOP.COMPANY.COM: 
klist
    Ticket cache: FILE:/tmp/krb5cc_0
    Default principal: hduser/admin@HADOOP.COMPANY.COM

    Valid starting     Expires            Service principal
    02/03/15 01:51:27  02/04/15 01:51:27  krbtgt/GDD.NL@HADOOP.COMPANY.COM
        renew until 02/03/15 01:51:27
```

#### 8. Verify that the KDC is issuing tickets

``` bash
# Run `kinit` to obtain a ticket and store it in a credential cache file
kinit user1
    Password for user1@HADOOP.COMPANY.COM:

# Let's see the ticket and also display the encryption type
klist  -e
    Ticket cache: FILE:/tmp/krb5cc_0
    Default principal: user1@HADOOP.COMPANY.COM

    Valid starting     Expires            Service principal
    02/03/15 02:32:42  02/04/14 02:32:42  krbtgt/HADOOP.COMPANY.COM@HADOOP.COMPANY.COM
        renew until 02/03/15 02:32:42, Etype (skey, tkt): aes256-cts-hmac-sha1-96, aes256-cts-hmac-sha1-96
```
This means that we got a ticket for `user1` and it is valid for `1 day`. In case I would have been logged in as user `user1`, I could have used `kinit` without specifying `user1` afterwards.

We can also destroy tickets:

``` bash
kdestroy
klist
    klist: No credentials cache found (ticket cache FILE:/tmp/krb5cc_0)
```

#### 9. Check that you can renew the Kerberos Tickets (This is important for Hue)

Why is TGT renewal important? Because some long running jobs might actually take advantage of renewing the ticket so they can continue running. Hue has a Kerberos Ticket Renewal instance. If you do not configure ticket renewal correctly, you won't be able to use Hue in a Kerberized environment. So how can we check?

```
kinit hduser/admin
klist
    Ticket cache: FILE:/tmp/krb5cc_0
    Default principal: hduser/admin@HADOOP.COMPANY.COM

    Valid starting     Expires            Service principal
    02/05/15 14:08:06  02/06/15 14:08:06  krbtgt/HADOOP.COMPANY.COM@HADOOP.COMPANY.COM
        renew until 02/05/15 14:08:06

kinit -R
    kinit: Ticket expired while renewing credentials
```

If you didn't get this error, congratulations! Because your Kerberos server is working properly :)

When you get a error similar to the one above, chances are that your `krbtgt/@` has a `max_renewable_life` time of `0`. The principals' max renewable life times are set in the KDB records with kadmin. By default new principals get a max_renewable_life of 0 if the max renewable life for the realm is not set in kdc.conf. The `kdb5_util` utility sets the max renewable life for the TGS the same way.

Let's validate:

```
kadmin -p hduser/admin
kadmin:  getprinc hduser/admin
    Principal: hduser/admin@HADOOP.COMPANY.COM
    Expiration date: [never]
    Last password change: Mon Feb 03 01:15:15 PST 2014
    Password expiration date: [none]
    Maximum ticket life: 1 day 00:00:00
    Maximum renewable life: 0 days 00:00:00
    Last modified: Mon Feb 03 01:15:15 PST 2014 (root/admin@HADOOP.COMPANY.COM)
    Last successful authentication: [never]
    Last failed authentication: [never]
    Failed password attempts: 0
    Number of keys: 6
    Key: vno 1, aes256-cts-hmac-sha1-96, no salt
    Key: vno 1, aes128-cts-hmac-sha1-96, no salt
    Key: vno 1, des3-cbc-sha1, no salt
    Key: vno 1, arcfour-hmac, no salt
    Key: vno 1, des-hmac-sha1, no salt
    Key: vno 1, des-cbc-md5, no salt
    MKey: vno 1
    Attributes:
    Policy: [none]
```

As you can see the maximum renewable life is 0 days.

Where are these renewable lifetimes set?
* In the `/var/kerberos/krb5kdc/kdc.conf`:`max_life` and `max_renewable_life`. 
* In the `/etc/krb5.conf`:`ticket_lifetime` and `renew_lifetime`.

Unfortunately setting the `max_life` and `max_renewable_life` in `/var/kerberos/krb5kdc/kdc.conf` and restarting the `kadmin` and `krb5kdc` services isn't enough, because the value was already saved in the `KDB`. So the quick fix would be to set the renew lifetime for the existing user and krbtgt realm. If you do not have too many users, you could also recreate the KDB using `kdb5_util create -s`. Before recreating the database, you need to delete the principal* file from `/var/kerberos/krb5kdc`.

The quick fix is to change the maxlife for the (all) user(s) and krbtgt/REALM principal can be set with:

``` bash
kadmin:  modprinc -maxlife 1days -maxrenewlife 7days +allow_renewable krbtgt/HADOOP.COMPANY.COM@HADOOP.COMPANY.COM
> Principal "krbtgt/HADOOP.COMPANY.COM@HADOOP.COMPANY.COM" modified.
kadmin:  modprinc -maxlife 1days -maxrenewlife 7days +allow_renewable krbtgt/HADOOP.COMPANY.COM@HADOOP.COMPANY.COM
> Principal "krbtgt/HADOOP.COMPANY.COM@HADOOP.COMPANY.COM" modified.
kadmin:  getprinc hduser/admin
    Principal: hduser/admin@HADOOP.COMPANY.COM
    Expiration date: [never]
    Last password change: Mon Feb 03 01:15:15 PST 2015              
    Password expiration date: [none]
    Maximum ticket life: 1 day 00:00:00
    Maximum renewable life: 7 days 00:00:00
    Last modified: Wed Feb 05 14:32:52 PST 2015 (hduser/admin@HADOOP.COMPANY.COM)
    Last successful authentication: [never]
    Last failed authentication: [never]
    Failed password attempts: 0
    Number of keys: 6
    Key: vno 1, aes256-cts-hmac-sha1-96, no salt
    Key: vno 1, aes128-cts-hmac-sha1-96, no salt
    Key: vno 1, des3-cbc-sha1, no salt
    Key: vno 1, arcfour-hmac, no salt
    Key: vno 1, des-hmac-sha1, no salt
    Key: vno 1, des-cbc-md5, no salt
    MKey: vno 1
    Attributes:
    Policy: [none]
```
And the maximum renewable life changed to 7 days.

We now have a working KDC, which can issue tickets and we can create new principals.

### Setting up cross realm trust between Active Directory and Kerberos KDC

> To Do: [configure cross-realm trust with Active Directory](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_sg_hadoop_security_active_directory_integrate.html)


### Setting up Kerberos authentication for Hadoop with Cloudera Manager

#### Create a KDC account for the Cloudera Manager user


Enable strong encrypBon in Java  
Set KDC hostname and realm on all Hadoop nodes  
Create Kerberos principals   
Create and deploy Kerberos keytab files  
Shut down all Hadoop daemons  
Enable Hadoop security  
Configure HDFS security opBons  
Configure YARN/MapReduce security opBons  
Restart Hadoop daemons   
Verify that everything works


## Sentry 

**Adding the Sentry Service Using Cloudera Manager**

	 1. On the Home page, click  to the right of the cluster name and select **Add a Service**. 
	 2. Select the **Sentry** service and click **Continue**.
	 3. Select the radio button next to the **Services** on which the new service should depend and click Continue.
	 4. Customise the assignment of **role instances to hosts**. 
	 5. Configure **database settings** (using custom MySQL database) and **test connectivity**.
	 6. Click **Continue** then click **Finish**. You are returned to the Home page.
	 7. Verify the new service is started properly by checking the health status for the new service. If the Health Status is **Good**, then the service started properly.
	 8. To use the Sentry service, begin by enabling **Hive** and **Impala** for the service.

**Before Enabling the Sentry Service**

**Disable impersonation for HiveServer2 in the Cloudera Manager Admin Console:**
	1. Go to the Hive service.
	2. Click the Configuration tab.
	3. Select Scope > HiveServer2.
	4. Select Category > Main.
	5. De-select HiveServer2 Enable Impersonation.
	6. Click Save Changes to commit the changes.

**If you are using YARN, enable the Hive user to submit YARN jobs.**
	1. Open the Cloudera Manager Admin Console and go to the YARN service.
	2. Click the Configuration tab.
	3. Select Scope > NodeManager.
	4. Select Category > Security.
	5. Ensure the Allowed System Users property includes the hive user. If not, add hive.
	6. Click Save Changes to commit the changes.
	7. Repeat steps 1-6 for every NodeManager role group for the YARN service that is associated with Hive.
	8. Restart the YARN service.

**Enabling the Sentry Service for Hive**

	1. Go to the Hive service.
	2. Click the Configuration tab.
	3. Select Scope > Hive (Service-Wide).
	4. Select Category > Main.
	5. Locate the Sentry Service property and select Sentry.
	6. Click Save Changes to commit the changes.
	7. Restart the Hive service.


**Enabling the Sentry Service for Impala**

	1. Enable the Sentry service for Hive (as instructed above).
	2. Go to the Impala service.
	3. Click the Configuration tab.
	4. Select Scope > Impala (Service-Wide).
	5. Select Category > Main.
	6. Locate the Sentry Service property and select Sentry.
	7. Click Save Changes to commit the changes.
	8. Restart Impala.

**Enabling the Sentry Service for Hue**

	1. To interact with Sentry using Hue, enable the Sentry service as follows:
	2. Enable the Sentry service for Hive and/or Impala (as instructed above).
	3. Go to the Hue service.
	4. Click the Configuration tab.
	5. Select Scope > Hue (Service-Wide).
	6. Select Category > Main.
	7. Locate the Sentry Service property and select Sentry.
	8. Click Save Changes to commit the changes.
	9. Restart Hue.

**Setting Up Hive Authorization with Sentry**


