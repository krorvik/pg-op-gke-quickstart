#!/bin/bash

#Create with rw storage access, and a bit larger machine than usual so we con fit some pods
gcloud container clusters create rl-poc --zone=europe-north1-a --scopes=storage-rw --billing-project rl-poc --machine-type n1-standard-2

#kubectl create -f manifests/operator-service-account-rbac.yaml
#kubectl create -f manifests/postgres-pod-config.yaml
#kubectl create -f manifests/postgres-operator.yaml
#sleep 20s # operator needs to be running before the below is run
#kubectl create -f manifests/postgresql-operator-default-configuration.yaml
