#!/bin/bash

. ./config.sh
PROJECT="$CUSTOMER-$ID"

kubectl create -f operator-service-account-rbac.yaml
kubectl create -f postgres-pod-config.yaml
kubectl create -f postgres-operator.yaml
kubectl create -f postgresql-operator-default-configuration.yaml
kubectl create -f minimal-postgres-manifest.yaml
