# High Availability Configuration

## Name Node HA 

*Enabling High Availability with Quorum-based Storage*

* CM 5 supports a NameNode HA wizard
  * {HDFS service} -> Actions -> Enable High Availability
* Locating the Journal Quroum Managers
* Understanding Zookeeper's role
* You may want to relocate services as a cluster grows
* Best practices vary with cluster size
  * Few nodes: master & workers combined, utility & edge roles combined
  * Many nodes: dedicated roles per host
  * You may have hardware designed for each role
  * Fewer disks, RAID on master nodes
  * RAM, many spindles on worker nodes

*Post Setup Steps for Hue and Hive*

There are several configuration changes you must make in order to successfully enable High Availability, whether you will be using Quorum-based storage or NFS-mounted shared edits directory. Before you enable HA, you must do the following:

Configure the HDFS Web Interface Role for Hue to be a HTTPFS role. See Configuring Hue to work with High Availability.
Upgrade the Hive Metastore to use High Availability. You must do this for each Hive service in your cluster. See Upgrading the Hive Metastore for HDFS High Availability.

*Configuring Hue to work with High Availability*

* From the *Services* tab, select your *HDFS* service.
* Click the *Instances* tab.
* Click the *Add Role Instances* button.
* Under the *HttpFS* column, select a host where you want to install the HttpFS role and click Continue.
* After you are returned to the Instances page, select the new *HttpFS* role.
* From the *Actions for Selected* menu, select *Start* (and *confirm*).
* After the command has completed, go to the *Services* tab and select your *Hue* service.
* From the *Configuration* tab, select *Edit*.
* The HDFS Web Interface Role property will now show the *HttpFS* role you just added. Select it instead of the namenode role, and Save your changes. (The HDFS Web Interface Role property is under the Service-Wide Configuration category.)
* *Restart* the *Hue* service for the changes to take effect.

*Upgrading the Hive Metastore for HDFS High Availability*

To upgrade the Hive metastore to work with High Availability, do the following:

* Go to the Services tab and select the Hive service.
* From the Actions menu, select Stop....
> *Note:* You may want to stop the Hue and Oozie services first, if present, as they depend on the Hive service.
* Confirm that you want to stop the service.
* When the service has stopped, back up the Hive metastore database to persistent storage.
> ToDo: add Hive metastore backup command
* From the Actions menu, click Update Hive Metastore NameNodes... and confirm the command.
* From the Actions menu on the Hive Service page, Start... the Hive MetaStore Service. Also restart the Hue and Impala services if you stopped them prior to updating the metastore.
