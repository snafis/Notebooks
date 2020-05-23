# Backup and Disaster Recovery

## HDFS Replication

* Choose a replication cluster

* Add that cluster as a peer in Cloudera Manager
  * `Administration`>`Peers`>`Add Peer`
  * Peer Name = `MyPeerCluster`
  * Peer URL = `http://fqdn:7180`
  * Peer Admin Username = `admin`
  * Peer Admin Password = `admin`

* Add Peer Cluster IP addresses to `/etc/hosts` files of all the nodes in this cluster.
```
54.247.76.167 ip-10-103-216-69.eu-west-1.compute.internal                  
54.195.246.27 ip-10-82-151-17.eu-west-1.compute.internal                     
54.217.239.180 ip-10-81-154-66.eu-west-1.compute.internal                     
176.34.127.127 ip-10-8-8-8.eu-west-1.compute.internal                       
176.34.181.183 ip-10-85-130-11.eu-west-1.compute.internal
```
* In CM, set `dfs.client.use .datanode.hostname` to `TRUE`.

* Schedule a HDFS/Hive Replication Job
  * Backup>Replications>Create>HDFS Replication
  * Select appropriate Source and Destination directories

* Browse the filesystem to see the output in `http://ec2-52-17-214-16.eu-west-1.compute.amazonaws.com:50070/explorer.html`
  

## HDFS Snapshots

### Create a snapshot of HDFS directory

```
sudo -u hdfs hadoop dfs -mkdir /snapshot
echo "shapshot data" | sudo -u hdfs hadoop dfs -put - /snapshot/snapshot-file.txt
sudo -u hdfs hadoop dfs -cat /snapshot/snapshot-file.txt
> shapshot data
sudo -u hdfs hadoop dfsadmin -allowSnapshot  /snapshot
> Allowing snaphot on /snapshot succeeded
```

Navigate to the NameNode Web UI. Find the “Snapshot” link in the top menu of the webpage and see the increased number of snapshotable directories: `http://ec2-52-17-214-16.eu-west-1.compute.amazonaws.com:50070/dfshealth.html#tab-snapshot`

Now, let’s create a snapshot of our `/snapshot` directory!

```
sudo -u hdfs hadoop dfs -createSnapshot /snapshot first-snapshot
> Created snapshot /snapshot/.snapshot/first-snapshot
```
The snapshot name (“first-snapshot” in our case) is an optional argument. When it is omitted, a default name is generated using a timestamp with the format “syyyyMMdd-HHmmss.SSS”, e.g. “s20140730-052810.965″.

### “Accidentally” remove the important file

```
sudo -u hdfs hdfs dfs -rm -r -skipTrash /snapshot
> rm: The directory /snapshot cannot be deleted since /snapshot is snapshottable and already has snapshots

sudo -u hdfs hdfs dfs -rm -r /snapshot/snapshot-file.txt
> 15/05/19 11:59:49 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 1440 minutes, Emptier interval = 0 minutes.
> Moved: 'hdfs://nameservice1/snapshot/snapshot-file.txt' to trash at: hdfs://nameservice1/user/hdfs/.Trash/Current
```

### Recover the file from the snapshot

``` 
sudo -u hdfs hdfs dfs -lsr /snapshot/.snapshot
> lsr: DEPRECATED: Please use 'ls -R' instead.
> drwxr-xr-x   - hdfs supergroup          0 2015-05-19 11:51 /snapshot/.snapshot/first-snapshot
> -rw-r--r--   3 hdfs supergroup         14 2015-05-19 11:45 /snapshot/.snapshot/first-snapshot/snapshot-file.txt

sudo -u hdfs hdfs dfs -cat /snapshot/.snapshot/first-snapshot/snapshot-file.txt
> shapshot data

sudo -u hdfs hdfs dfs -cp /snapshot/.snapshot/first-snapshot/snapshot-file.txt /snapshot

sudo -u hdfs hdfs dfs -cat /snapshot/snapshot-file.txt
> shapshot data

```
