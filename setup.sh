#!/bin/bash

. ./config.sh

ID=$(date +%s | md5sum | cut -b 1-8 | xargs)
PROJECT="$CUSTOMER-$ID"
echo $PROJECT > .PROJECT

# Create project
gcloud projects create $PROJECT
gcloud config set project $PROJECT
gcloud alpha billing projects link $PROJECT --billing-account=$BILLINGACCOUNT
gcloud services enable container.googleapis.com --project $PROJECT

gcloud container clusters create $PROJECT --zone=$ZONE --scopes=storage-rw --billing-project $PROJECT

cat << EOF > postgres-pod-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-pod-config
  namespace: default
data:
  # Enable to turn backups on
  USE_WALG_BACKUP: "true"
  USE_WALG_RESTORE: "true"
  WALG_LOG_LEVEL: "DEVEL"
  WALG_GS_PREFIX: "gs://$PROJECT/spilo/\$(SCOPE)"
  CLONE_WALG_GS_PREFIX: "gs://$PROJECT/spilo/\$(CLONE_SCOPE)"
EOF


kubectl create -f operator-service-account-rbac.yaml
kubectl create -f postgres-pod-config.yaml
kubectl create -f postgres-operator.yaml
sleep 30s
kubectl create -f postgresql-operator-default-configuration.yaml
gsutil mb -b on -l $REGION gs://$PROJECT
