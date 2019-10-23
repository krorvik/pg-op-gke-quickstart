#!/bin/bash

. ./config.sh

echo $PROJECT > ID

# Create project
gcloud projects create $PROJECT
gcloud config set project $PROJECT
gcloud alpha billing projects link $PROJECT --billing-account=$BILLINGACCOUNT
gcloud services enable container.googleapis.com --project $PROJECT

gcloud container clusters create $CLUSTER --zone=$ZONE --scopes=storage-rw --billing-project $PROJECT

kubectl create -f operator-service-account-rbac.yaml
kubectl create -f postgres-pod-config.yaml
kubectl create -f postgres-operator.yaml
sleep 10s
kubectl create -f postgresql-operator-default-configuration.yaml
