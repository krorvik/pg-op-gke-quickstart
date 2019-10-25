#!/bin/bash

. ./config.sh
PROJECT="$CUSTOMER-$ID"

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
  # We need to provide the bucket for WAL-G operations. DO NOT quote these vars - it breaks spilo configuration. 
  WALG_GS_PREFIX: gs://$PROJECT/spilo/\$(SCOPE)
  CLONE_WALG_GS_PREFIX: gs://$PROJECT/spilo/\$(CLONE_SCOPE)
EOF
kubectl create -f manifests/postgres-operator.yaml
kubectl create -f manifests/postgresql-operator-default-configuration.yaml
kubectl create -f manifests/minimal-postgres-manifest.yaml
