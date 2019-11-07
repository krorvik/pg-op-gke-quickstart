# Scope

This is a simple rundown of all the steps to get a zalando/postgres-operator cluster up in GKE, in the default namespace, with basebackups/WAL archiving in GCS, using WAL-G. It is intended as a POC.

Reference: https://github.com/zalando/postgres-operator

Blog entry: https://www.redpill-linpro.com/techblog/2019/09/28/postgres-in-kubernetes.html

You need a google account, and a related billing account set up for Google Cloud (which is out of scope here). The code below will incur some cost, but no more than a sixpack will as long as you remember tearing things down.

The steps below create a postgres operator, and a cluster that backs up to a GCS bucket. The clone step may be performed to do a disaster recovery as well. 

# Steps

Edit config.sh to your liking.

## Setup project in GKE

```console
$ gcloud auth login  # (Pulls up browser)
```

And then create the project with related setup:

```console
$ ./init.sh
```

## Set up the operator

```
$ ./setup.sh
```

This will create the operator, as well as a cluster in the last line, called acid-minimal-cluster. 

## Cluster ops

```console
$ kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
acid-minimal-cluster-0               1/1     Running   0          8m49s
postgres-operator-599fd68d95-mn2k6   1/1     Running   0          15m

$ kubectl exec -it acid-minimal-cluster-0 su postgres
postgres@acid-minimal-cluster-0:~$ patronictl list
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
|       Cluster        |         Member         |    Host   |  Role  |      State       | TL | Lag in MB |
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
| acid-minimal-cluster | acid-minimal-cluster-0 | 10.12.2.5 | Leader |     running      |  1 |         0 |
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
```

Note we use "su postgres", since we *don't* want to reset environment vars with a full login.  

## Clone or restore

To clone or restore a cluster, you need the UID of that cluster. You can see how that's done in start_restore.sh. To test, run that script - it will get the UID of acid-minimal-cluster and pull up a clone. 

## Tear down

```console
$ ./teardown.sh
```

At this point you may repeat the steps from setup.sh if you want to change stuff. That will tear down all pods and resources, and let you quickly start over.

Note that this sometimes hangs after a few resources are deleted. Cancel it and run again in that case. 

If you are done, remove all traces using:

```console
$ ./exit.sh
```

This will remove the project and gs bucket. Beware that google has a project quota, so don't go crazy. You may undelete the project if you like (use undelete instead of delete for the command from setup.sh). 
