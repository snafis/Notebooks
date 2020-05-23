# Apache Sentry

## Introduction
Apache Sentry (incubating) is a granular, role-based authorization module for Hadoop. Sentry provides the ability to control and enforce precise levels of privileges on data for authenticated users and applications on a Hadoop cluster. Sentry currently works out of the box with Apache Hive, Hive Metastore/HCatalog, Apache Solr, Cloudera Impala and HDFS (limited to Hive table data).

Sentry is designed to be a pluggable authorization engine for Hadoop components. It allows you to define authorization rules to validate a user or application’s access requests for Hadoop resources. Sentry is highly modular and can support authorization for a wide variety of data models in Hadoop.

## Key Concepts
  
* **Authentication** - Verifying credentials to reliably identify a user
* **Authorization** - Limiting the user’s access to a given resource
* **User** - Individual identified by underlying authentication system
* **Group** - A set of users, maintained by the authentication system
* **Privilege** - An instruction or rule that allows access to an object
* **Role** - A set of privileges; a template to combine multiple access rules
* **Authorization models** - Defines the objects to be subject to authorization rules and the granularity of actions allowed. For example, in the SQL model, the objects can be databases or tables, and the actions are SELECT, INSERT, CREATE and so on. For the Search model, the objects are indexes, collections and documents; the access modes are query, update and so on.

## Architecture Overview

### Sentry Components

![Apache Sentry Components](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/images/sentry_hadoop_ecosystem.png)

There are three components involved in the authorization process:

**Sentry Server**
The Sentry RPC server manages the authorization metadata. It supports interfaces to securely retrieve and manipulate the metadata.

**Data Engine**
This is a data processing application such as Hive or Impala that needs to authorize access to data or metadata resources. The data engine loads the Sentry plugin and all client requests for accessing resources are intercepted and routed to the Sentry plugin for validation.

**Sentry Plugin**
The Sentry plugin runs in the data engine. It offers interfaces to manipulate authorization metadata stored in the Sentry server, and includes the authorization policy engine that evaluates access requests using the authorization metadata retrieved from the server.


### Role-Based Access Control

Role-based access control (RBAC) is a powerful mechanism to manage authorization for a large set of users and data objects in a typical enterprise. New data objects get added or removed, users join, move, or leave organisations all the time. RBAC makes managing this a lot easier. 

Sentry relies on underlying authentication systems such as Kerberos or LDAP to identify the user. It then uses the group mapping mechanism configured in Hadoop to ensure that Sentry sees the same group mapping as other components of the Hadoop ecosystem.

![Role Based Access Control](https://www.safaribooksonline.com/library/view/hadoop-security/9781491900970/diagrams/ch07-sentry_relationships.png

Consider users Alice and Bob who belong to an Active Directory (AD) group called finance-department. Bob also belongs to a group called finance-managers. In Sentry, you first create roles and then grant privileges to these roles. For example, you can create a role called Analyst and grant SELECT on tables Customer and Sales to this role.

The next step is to join these authentication entities (users and groups) to authorization entities (roles). This can be done by granting the Analyst role to the finance-department group. Now Bob and Alice who are members of the finance-department group get SELECT privilege to the Customer and Sales tables. If a new joiner Carol joins the Finance Department, all you need to do is add her to the finance-department group in AD. This will give Carol access to data from the Sales and Customer tables.

### Unified Authorization

As illustrated below, Apache Sentry works with multiple Hadoop components. At the heart you have the Sentry Server which stores authorization metadata and provides APIs for tools to retrieve and modify this metadata securely.

Note that the Sentry server only facilitates the metadata. The actual authorization decision is made by a policy engine which runs in data processing applications such as Hive or Impala. Each component loads the Sentry plugin which includes the service client for dealing with the Sentry service and the policy engine to validate the authorization request.

![Apache Sentry](https://camo.githubusercontent.com/3f2887bbb712c9f5b69f56072054ef793ae0b8a2/687474703a2f2f626c6f672e636c6f75646572612e636f6d2f77702d636f6e74656e742f75706c6f6164732f323031332f30372f556e7469746c65642e706e67)


## Sentry Integration with the Hadoop Ecosystem

### Hive and Sentry

Consider an example where Hive gets a request to access an object in a certain mode by a client. If Bob submits the following Hive query:
``` sql
select * from production.sales
```
![Hive-Sentry](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/images/sentry_hive.png)

Hive will identify that user Bob is requesting SELECT access to the Sales table. At this point Hive will ask the Sentry plugin to validate Bob’s access request. The plugin will retrieve Bob’s privileges related to the Sales table and the policy engine will determine if the request is valid.


> **To Do:** 
> * Hue and Sentry
> * Impala and Sentry
> * HDFS and Sentry

## Authorization Administration

> **To Do:** 
> * Sentry Policy File Authorization

### Sentry Service

The Sentry service is a RPC server that stores the authorization metadata in an underlying relational database and provides RPC interfaces to retrieve and manipulate privileges. It supports secure access to services using Kerberos. The service serves authorization metadata from the database backed storage; it does not handle actual privilege validation. The Hive and Impala services are clients of this service and will enforce Sentry privileges when configured to use Sentry.

![Sentry Service](https://www.safaribooksonline.com/library/view/hadoop-security/9781491900970/diagrams/ch07-sentry_service.png.jpg)

Hue now supports a Security app to manage Sentry authorization. This allows users to explore and change table permissions. Here/s a video blog that demonstrates its functionality.

**Prerequisites**

  * **CDH 5.1.x** (or later) managed by Cloudera Manager 5.1.x (or later). 
  * **HiveServer2** and the **Hive Metastore** running with strong authentication. For HiveServer2, strong authentication is either **Kerberos** or **LDAP**. For the Hive Metastore, only Kerberos is considered strong authentication (to override, see Securing the Hive Metastore).
  * **Impala 1.4.0 (or later)** running with strong authentication. With Impala, either **Kerberos** or **LDAP** can be configured to achieve strong authentication.
  * Implement **Kerberos** authentication on your cluster. 


### Hive Authorization

![Hive Sentry Architecture](https://www.safaribooksonline.com/library/view/hadoop-security/9781491900970/diagrams/ch07-hive_sentry.png.jpg)
