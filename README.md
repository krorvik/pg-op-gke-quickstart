# Scope

This is a simple rundown of all the steps to get a zalando/postgres-operator cluster up in GKE, in the default namespace, with basebackups/WAL archiving in GCS, using WAL-G. It is intended as a POC.

Reference: https://github.com/zalando/postgres-operator

You need a google account, and a related billing account set up for Google Cloud (which is out of scope here). The code below will incur some cost, but no more than a sixpack will as long as you remember tearing things down.

The steps below create a postgres operator, and a cluster that backs up to a GCS bucket. The clone step may be performed to do a disaster recovery as well. 

# Steps

Edit config.sh to your liking.

# Setup project in GKE

```console
$ gcloud auth login  # (Pulls up browser)
```

And then create the project with related setup:

```console
$ ./init.sh
```

# Set up the operator

```
$ ./setup.sh
```

# Cluster ops

```console
$  kubectl create -f minimal-postgres-manifest.yaml 
postgresql.acid.zalan.do/acid-minimal-cluster created

$ kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
acid-minimal-cluster-0               1/1     Running   0          8m49s
acid-minimal-cluster-1               1/1     Running   0          8m10s
postgres-operator-599fd68d95-mn2k6   1/1     Running   0          15m

$ kubectl exec -it acid-minimal-cluster-0 su postgres
postgres@acid-minimal-cluster-0:~$ patronictl list
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
|       Cluster        |         Member         |    Host   |  Role  |      State       | TL | Lag in MB |
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
| acid-minimal-cluster | acid-minimal-cluster-0 | 10.12.2.5 | Leader |     running      |  1 |         0 |
| acid-minimal-cluster | acid-minimal-cluster-1 | 10.12.2.6 |        |     running      |    |         0 |
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
```

# Get the UID of the cluster 

This is needed for clone operations:

```console
$ kubectl get postgresql acid-minimal-cluster -o yaml | grep uid
  uid: <uid>
```

Store this so you can use it later.

# Delete the cluster

Backup is kept in GCS:


```console
$ kubectl delete postgresql acid-monitoring-cluster
postgresql.acid.zalan.do "acid-monitoring-cluster" deleted
```

# Recover the cluster from GCS

```console
$ kubectl create -f restore-minimal-postgres-manifest.yaml 
postgresql.acid.zalan.do/acid-rest-cluster created
```

# Tear down

```console
$ ./teardown.sh
```
