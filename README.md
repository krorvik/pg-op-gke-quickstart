# Scope

This is a simple rundown of all the steps to get a zalando/postgres-operator cluster up in GKE, in the default namespace, with basebackups/WAL archiving in GCS. It is intended as a POC.

WARNING: Some configuration must be performed to get this going. See minimal manifest diff that should work below. 

Reference: https://github.com/zalando/postgres-operator

You need a google account, and a related billing account set up for Google Cloud (which is out of scope here). The code below will incur some cost, but no more than a sixpack will as long as you remember tearing things down.

# Steps

```console
# Clone project to get templates

$ git clone https://github.com/zalando/postgres-operator
$ cd postgres-operator/manifests

###
###  AT THIS POINT; apply config diff below. And consider changing the project name in the code below. 
###

# Setup project in GKE

$ gcloud auth login  # (Pulls up browser)

$ gcloud projects create finnpoc
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/finnpoc].
Waiting for [operations/cp.8944039908840415495] to finish...done.
     
$ gcloud config set project finnpoc
Updated property [core/project].

$ gcloud alpha billing accounts list
ACCOUNT_ID            NAME                           OPEN  MASTER_ACCOUNT_ID
<ID>				  CRD                            True

$ gcloud alpha billing projects link finnpoc --billing-account=<ID>
billingAccountName: billingAccounts/<ID>
billingEnabled: true
name: projects/finnpoc/billingInfo
projectId: finnpoc

$ gcloud services enable container.googleapis.com --project finnpoc
Operation "operations/acf.a8db7ce2-a356-4354-9d69-6fbe56b1364f" finished successfully.

### Create backup bucket in GCS

$ gsutil mb -b on -c nearline -l europe-north1 gs://finnpoc

# Create a cluster

$ gcloud container clusters create pgcluster --zone=europe-north1-a --scopes=storage-rw --billing-project finnpoc
<SNIP>
Creating cluster pgcluster in europe-north1-a... Cluster is being health-checked (master is healthy)...done.
Created [https://container.googleapis.com/v1/projects/finnpoc/zones/europe-north1-a/clusters/pgcluster].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/europe-north1-a/pgcluster?project=finnpoc
kubeconfig entry generated for pgcluster.
NAME       LOCATION         MASTER_VERSION  MASTER_IP       MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
pgcluster  europe-north1-a  1.13.7-gke.8    35.228.239.140  n1-standard-1  1.13.7-gke.8  3          RUNNING

### Install operator

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

# Cluster ops

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
$ gsutil rm -rf gs://finnpoc

```

# Needed manifest diff to get things running

```diff
diff --git a/manifests/postgres-operator.yaml b/manifests/postgres-operator.yaml
index 7b74b80..ae01224 100644
--- a/manifests/postgres-operator.yaml
+++ b/manifests/postgres-operator.yaml
@@ -33,2 +33,2 @@ spec:
-        - name: CONFIG_MAP_NAME
-          value: "postgres-operator"
+        #- name: CONFIG_MAP_NAME
+        #  value: "postgres-operator"
@@ -36,2 +36,2 @@ spec:
-        # - name: POSTGRES_OPERATOR_CONFIGURATION_OBJECT
-        #  value: postgresql-operator-default-configuration
+        - name: POSTGRES_OPERATOR_CONFIGURATION_OBJECT
+          value: postgresql-operator-default-configuration
diff --git a/manifests/postgres-pod-config.yaml b/manifests/postgres-pod-config.yaml
new file mode 100644
index 0000000..ad296e6
--- /dev/null
+++ b/manifests/postgres-pod-config.yaml
@@ -0,0 +1,8 @@
+apiVersion: v1
+kind: ConfigMap
+metadata:
+  name: postgres-pod-config
+  namespace: default
+data:
+  WALE_GS_PREFIX: gs://finnpoc/spilo/$(SCOPE)
+  CLONE_WALE_GS_PREFIX: gs://finnpoc/spilo/$(CLONE_SCOPE)
diff --git a/manifests/postgresql-operator-default-configuration.yaml b/manifests/postgresql-operator-default-configuration.yaml
index 3c79828..3f0b160 100644
--- a/manifests/postgresql-operator-default-configuration.yaml
+++ b/manifests/postgresql-operator-default-configuration.yaml
@@ -7 +7 @@ configuration:
-  docker_image: registry.opensource.zalan.do/acid/spilo-11:1.5-p9
+  docker_image: krorvik/spilo:tzfix
@@ -35 +35 @@ configuration:
-    # pod_environment_configmap: ""
+    pod_environment_configmap: postgres-pod-config
@@ -38 +38 @@ configuration:
-    pod_service_account_name: operator
+    pod_service_account_name: zalando-postgres-operator
```

# Spilo changes to enable GCS backups

The changes below are present in the docker_image used above. They fix a bug in WAL-E where timestamps from GCS are naive - which breaks the clone_with_wale.py script in the spilo image. 

```
krorvik@krorvik:/home/krorvik/code/spilo$ git diff
diff --git a/postgres-appliance/bootstrap/clone_with_wale.py b/postgres-appliance/bootstrap/clone_with_wale.py
index f2a2f6f..b95eddb 100755
--- a/postgres-appliance/bootstrap/clone_with_wale.py
+++ b/postgres-appliance/bootstrap/clone_with_wale.py
@@ -70,6 +70,11 @@ def choose_backup(output, recovery_target_time):
     match_timestamp = match = None
     for backup in backup_list:
         last_modified = parse(backup['last_modified'])
+        # Here is where WAL-E returns a naive time, last_modified
+        # If running on Google Storage. Detect that, and set to same as recovery target if so
+        # The latter is checked to have a tzinfo in read_configuration().
+        tz = last_modified.tzinfo or recovery_target_time.tzinfo
+        last_modified = tz.localize(last_modified)
         if last_modified < recovery_target_time:
             if match is None or last_modified > match_timestamp:
                 match = backup
```