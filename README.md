```console
$ gcloud projects create rl-pgpoc
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/rl-pgpoc].
$ gcloud config set project rl-pgpoc
$ gcloud alpha billing projects link rl-pgpoc --billing-account=<ID>
name: projects/rl-pgpoc/billingInfo
projectId: rl-pgpoc
$ gcloud services enable container.googleapis.com --project rl-pgpoc
```
```console
$ gsutil mb -b on -c nearline -l europe-north1 gs://pgbucket-rl
```
```console
$ gcloud container clusters create pgcluster --zone=europe-north1-a --scopes=storage-rw --billing-project rl-pgpoc
Created [https://container.googleapis.com/v1/projects/rl-pgpoc/zones/europe-north1-a/clusters/pgcluster].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/europe-north1-a/pgcluster?project=rl-pgpoc
```
```console
```
```console
$ gsutil rm -rf gs://pgbucket-rl