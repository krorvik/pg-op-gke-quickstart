#!/bin/bash

PROJECT=$(cat .PROJECT | xargs)

kubectl delete postgresql acid-minimal-cluster
kubectl delete postgresql acid-restore-cluster
kubectl delete statefulset acid-minimal-cluster
kubectl delete statefulset acid-restore-cluster
kubectl delete pvc pgdata-acid-minimal-cluster-0
kubectl delete pvc pgdata-acid-restore-cluster-0
kubectl delete service acid-minimal-cluster
kubectl delete service acid-minimal-cluster-config
kubectl delete service acid-minimal-cluster-repl
kubectl delete service acid-restore-cluster
kubectl delete service acid-restore-cluster-config
kubectl delete service acid-restore-cluster-repl
kubectl delete poddisruptionbudgets.policy postgres-acid-minimal-cluster-pdb
kubectl delete poddisruptionbudgets.policy postgres-acid-restore-cluster-pdb
kubectl delete -f operator-service-account-rbac.yaml
kubectl delete -f postgres-pod-config.yaml
kubectl delete -f postgres-operator.yaml
kubectl delete -f postgresql-operator-default-configuration.yaml
gsutil rm -rf gs://$PROJECT/spilo/*
