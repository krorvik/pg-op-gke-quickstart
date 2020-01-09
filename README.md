# Scope

This is a simple rundown of all the steps to get a zalando/postgres-operator cluster up in GKE, in the default namespace, with basebackups/WAL archiving in GCS, using WAL-G. It is intended as a POC.

Reference: https://github.com/zalando/postgres-operator

Blog entry: https://www.redpill-linpro.com/techblog/2019/09/28/postgres-in-kubernetes.html

Note: Some improvements in postgres-operator has made the contents of this repo a bit simpler than the blogpost. 

You need a google account, and a related billing account set up for Google Cloud (which is out of scope here). Create a project - here, we use the name "rl-poc" both for the bucket and the project. The project must have a billing account coupled, and google kubernetes engine enabled. 

Example commands:

```console
$ gcloud config set project rl-poc 
$ gcloud alpha billing projects link rl-poc --billing-account=<billing account id>
$ gcloud services enable container.googleapis.com --project rl-poc
```

The steps below create a postgres operator, and a cluster that backs up to a GCS bucket. The clone step may be performed to do a disaster recovery as well. 

# Set up the operator

```
$ kubectl apply -f manifests/postgres-pod-config.yaml
$ kubectl apply -f manifests/operator-service-account-rbac.yaml
$ kubectl apply -f manifests/postgres-operator.yaml
$ sleep 20s # operator needs some init time before the next line works
$ kubectl apply -f manifests/postgresql-operator-default-configuration.yaml
```

At this point clusters can be created. See the rldemo-manifests for examples. 

# Cluster ops

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

# Tear down

```console
$ ./teardown.sh
```
