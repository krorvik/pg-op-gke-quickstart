#!/bin/bash

. ./config.sh
PROJECT="$CUSTOMER-$ID"

#Create with rw storage access, and a bit larger machine than usual so we con fit some pods
gcloud container clusters create $PROJECT --zone=$ZONE --scopes=storage-rw --billing-project $PROJECT --machine-type n1-standard-2


kubectl create -f manifests/operator-service-account-rbac.yaml
cat << EOF | kubectl create -f -
# This config map provides environment variables to the pods in postgresql clusters. They are used by the spilo image. 
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-pod-config
  namespace: default
data:
  # These three make sure we use WAL-G for all basebackup and archiving
  USE_WALG: "true"
  USE_WALG_BACKUP: "true"
  USE_WALG_RESTORE: "true"
  #WALG_GS_BUCKET: gs://$PROJECT
  # We need to provide the bucket for WAL-G operations. DO NOT quote these vars - it breaks spilo configuration. 
  WALG_GS_PREFIX: gs://$PROJECT/spilo/\$(SCOPE)
  CLONE_WALG_GS_PREFIX: gs://$PROJECT/spilo/\$(CLONE_SCOPE)
  #This forces standby creation to always use pg_basebackup. 
  WALE_BACKUP_THRESHOLD_PERCENTAGE: "100"   
EOF
kubectl create -f manifests/postgres-operator.yaml
sleep 20s # operator needs to be running before the below is run
kubectl create -f manifests/postgresql-operator-default-configuration.yaml
