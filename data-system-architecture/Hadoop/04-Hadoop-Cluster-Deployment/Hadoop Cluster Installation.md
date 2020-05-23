# Installing Hadoop 

Initial Installation Guide can be found here:
[Cloudera Hadoop Installation Guide](https://github.com/nafis/Big-Data-Development-Environment/blob/master/Cloudera-Installation/docs/Automated%20Installation%20by%20Cloudera%20Manager.md)


## CDH formats - RPM vs Package vs Tarballs

* CDH is available in multiple formats

  - **RPMs** for RHEL, CentOS
  - **Packages** for Ubuntu and SuSE Linux
  - **Parcels** for installation via Cloudera Manager
  - **Tarball** 

> **Recommendation:** Use the RPMs/Packages whenever possible as they include some features not available in the tarball:
>
> - automatic creation of *hdfs, yarn* and *mapred* users and groups 
> - *init* scripts to automatically start the Hadoop daemons, althrough these are not activated by default. 
> - configures the 'alternative' system to allow multiple configuration on the same machine



> **To Do Items:** 
> - [ ] Add Sequence Diagram Here to Give Visual Walkthrough of the Install Process

> - http://cdnjs.cloudflare.com/ajax/libs/raphael/2.1.0/raphael-min.js
> - http://cdnjs.cloudflare.com/ajax/libs/jquery/1.11.0/jquery.min.js
> - https://github.com/adrai/flowchart.js/blob/master/bin/flowchart-latest.js

> - [ ] Automated deployment
> - Red Hat's Kickstart
> - Debian Fully
