# Scope

This is a simple rundown of all the steps to get a zalando/postgres-operator cluster up in GKE, in the default namespace, with basebackups/WAL archiving in GCS, using WAL-G. It is intended as a POC.

* Reference: https://github.com/zalando/postgres-operator
* Reference: https://github.com/zalando/spilo
* Reference: https://github.com/zalando/patroni
* Blog entry: https://www.redpill-linpro.com/techblog/2019/09/28/postgres-in-kubernetes.html

Note: Some improvements in postgres-operator has made the contents of this repo a bit simpler than the blogpost. It now supports all major postgresql versions 9.4 to 12 that are not EOL. 

You need a google account, and a related billing account set up. Create a project - here, we use the name "rl-poc" both for the bucket and the project. The project must have a billing account coupled, and google kubernetes engine enabled. You also need a GCS bucket that the clusters can write to.

Example commands for preparation:

```console
$ gcloud auth login  #Pulls up auth in browser
$ gcloud config set project rl-poc 
$ gcloud alpha billing projects link rl-poc --billing-account=<billing account id>
$ gcloud services enable container.googleapis.com --project rl-poc
```

# Configuration details

The manifest files in this repo are set up to install the operator in the "default" namespace, and to listen *only* for postgresqls in that namespace. Please see https://postgres-operator.readthedocs.io/en/latest/administrator/#select-the-namespace-to-deploy-to for details if you want to change that. 

For a production setup, we recommend installing the operator in it's own namespace, "postgres-operator" for instance:

* https://postgres-operator.readthedocs.io/en/latest/administrator/#select-the-namespace-to-deploy-to

In that case it'd need to be told what namespaces to listen to:

* https://postgres-operator.readthedocs.io/en/latest/administrator/#specify-the-namespace-to-watch



# Set up the operator

```
$ kubectl apply -f manifests/postgres-pod-config.yaml
$ kubectl apply -f manifests/operator-service-account-rbac.yaml
$ kubectl apply -f manifests/postgres-operator.yaml
$ sleep 20s # operator needs some init time before the next line works
$ kubectl apply -f manifests/postgresql-operator-default-configuration.yaml
```

If the last one fails, wait a little and try again. 

When the last one succeeds, you should see a pod postgres-operator-<id> running, and at this point clusters can be created. See the examples/rldemo files for examples. 

# Cluster ops

```console
$ kubectl apply -f examples/rldemo-cluster.yaml

$ kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
rl-demo-cluster-0                    1/1     Running   0          8m49s
postgres-operator-599fd68d95-mn2k6   1/1     Running   0          15m

$ kubectl exec -it rl-demo-cluster-0 su postgres
postgres@rl-demo-cluster-0:~$ patronictl list
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
|       Cluster        |         Member         |    Host   |  Role  |      State       | TL | Lag in MB |
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
| rl-demo-cluster      | rl-demo-cluster-0      | 10.12.2.5 | Leader |     running      |  1 |         0 |
+----------------------+------------------------+-----------+--------+------------------+----+-----------+
```

Note we use "su postgres", since we *don't* want to reset environment vars with a full login.

## Resize a cluster

```console
$ kubectl edit postgresql rl-demo-cluster
```

Change the numberOfInstances, and save/quit. Operator will change the standby count. 

## Delete a cluster

```console
$ kubectl delete postgresql rl-demo-cluster
```

Now, you might not be able to delete a cluster this way if it never completed initialization. That is valid also if the cluster pods were never deemed ready. In that case, you might want to delete all objects manually. 

Look for:

* postgresqls
* statefulsets
* services
* secrets
* endpoints
* pvc

All will be prefixed with the name of the postgresql, so they're relatively easy to find. 

## Restore a cluster

```console
$ kubectl apply -f examples/rldemo-restore.yaml
```

The clone-section is the magic part. The same procedure can be used to clone a cluster while it is running, as long as you give it a new name. If it does not exist, you may reuse the name.

## Increase storage

You need to edit the PVC entries to change storage in GKE at the moment, due to operator limitations. Edit the PVC, and then restart (kill) the pods, standbys then master to resize. Yes, this incurs a little downtime. 


# Tear down

```console
$ ./teardown.sh
```
