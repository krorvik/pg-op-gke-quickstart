#!/bin/bash

. ./config.sh

#ID=$(date +%s | md5sum | cut -b 1-8 | xargs)
#ID="poc"
#PROJECT="$CUSTOMER-$ID"
#echo $PROJECT > .PROJECT

# Create project
#gcloud projects create $PROJECT
#gcloud config set project $PROJECT
#gcloud alpha billing projects link $PROJECT --billing-account=$BILLINGACCOUNT
#gcloud services enable container.googleapis.com --project $PROJECT

#gcloud container clusters create $PROJECT --zone=$ZONE --scopes=storage-rw --billing-project $PROJECT

kubectl create -f operator-service-account-rbac.yaml
kubectl create -f postgres-pod-config.yaml
kubectl create -f postgres-operator.yaml
#sleep 10s
kubectl create -f postgresql-operator-default-configuration.yaml
#gsutil mb -b on -l $REGION gs://$PROJECT
#sleep 10s
kubectl create -f minimal-postgres-manifest.yaml
