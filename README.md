# Scope

This is a simple rundown of all the steps to get a zalando/postgres-operator cluster up in GKE, in the default namespace, with basebackups/WAL archiving in GCS. It is intended as a POC.

Reference: https://github.com/zalando/postgres-operator

You need a google account, and a related billing account set up for Google Cloud (which is out of scope here). The code below will incur some cost, but no more than a sixpack will as long as you remember tearing things down.

# Steps

# Setup project in GKE

```console
$ gcloud auth login  # (Pulls up browser)

$ gcloud projects create rl-pgpoc
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/rl-pgpoc].
Waiting for [operations/cp.8944039908840415495] to finish...done.
     
$ gcloud config set project rl-pgpoc
Updated property [core/project].

$ gcloud alpha billing accounts list
ACCOUNT_ID            NAME                           OPEN  MASTER_ACCOUNT_ID
<ID>				  CRD                            True

$ gcloud alpha billing projects link rl-pgpoc --billing-account=<ID>
billingAccountName: billingAccounts/<ID>
billingEnabled: true
name: projects/rl-pgpoc/billingInfo
projectId: rl-pgpoc

$ gcloud services enable container.googleapis.com --project rl-pgpoc
Operation "operations/acf.a8db7ce2-a356-4354-9d69-6fbe56b1364f" finished successfully.
```

### Create backup bucket in GCS

```console
$ gsutil mb -b on -c nearline -l europe-north1 gs://pgbucket-rl
```

# Create a cluster

```console
$ gcloud container clusters create pgcluster --zone=europe-north1-a --scopes=storage-rw --billing-project rl-pgpoc
<SNIP>
Creating cluster pgcluster in europe-north1-a... Cluster is being health-checked (master is healthy)...done.
Created [https://container.googleapis.com/v1/projects/rl-pgpoc/zones/europe-north1-a/clusters/pgcluster].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/europe-north1-a/pgcluster?project=rl-pgpoc
kubeconfig entry generated for pgcluster.
NAME       LOCATION         MASTER_VERSION  MASTER_IP       MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
pgcluster  europe-north1-a  1.13.7-gke.8    35.228.239.140  n1-standard-1  1.13.7-gke.8  3          RUNNING
```

### Install operator

```console
$ kubectl create -f operator-service-account-rbac.yaml 
serviceaccount/zalando-postgres-operator created
clusterrole.rbac.authorization.k8s.io/zalando-postgres-operator created
clusterrolebinding.rbac.authorization.k8s.io/zalando-postgres-operator created

$ kubectl create -f postgres-pod-config.yaml 
configmap/postgres-pod-config created

$ kubectl create -f postgres-operator.yaml 
deployment.apps/postgres-operator created

$ sleep 30s

$ kubectl create -f postgresql-operator-default-configuration.yaml 
operatorconfiguration.acid.zalan.do/postgresql-operator-default-configuration created
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

# Tear down

```console
$ gcloud -q container clusters delete pgcluster
$ gsutil rm -rf gs://pgbucket-rl
```

