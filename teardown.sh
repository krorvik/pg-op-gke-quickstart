#!/bin/bash

PROJECT=$(cat .PROJECT | xargs)

kubectl delete --grace-period 0 --force  postgresql acid-minimal-cluster
kubectl delete --grace-period 0 --force  postgresql acid-restore-cluster
kubectl delete --grace-period 0 --force  statefulset acid-minimal-cluster
kubectl delete --grace-period 0 --force  statefulset acid-restore-cluster
kubectl delete --grace-period 0 --force  pvc pgdata-acid-minimal-cluster-0
kubectl delete --grace-period 0 --force  pvc pgdata-acid-minimal-cluster-0
kubectl delete --grace-period 0 --force  pvc pgdata-acid-restore-cluster-0
kubectl delete --grace-period 0 --force  service acid-minimal-cluster
kubectl delete --grace-period 0 --force  service acid-minimal-cluster-config
kubectl delete --grace-period 0 --force  service acid-minimal-cluster-repl
kubectl delete --grace-period 0 --force  service acid-restore-cluster
kubectl delete --grace-period 0 --force  service acid-restore-cluster-config
kubectl delete --grace-period 0 --force  service acid-restore-cluster-repl
kubectl delete --grace-period 0 --force  poddisruptionbudgets.policy postgres-acid-minimal-cluster-pdb
kubectl delete --grace-period 0 --force  poddisruptionbudgets.policy postgres-acid-restore-cluster-pdb
kubectl delete --grace-period 0 --force  -f operator-service-account-rbac.yaml
kubectl delete --grace-period 0 --force  -f postgres-pod-config.yaml
kubectl delete --grace-period 0 --force  -f postgres-operator.yaml
kubectl delete --grace-period 0 --force  -f postgresql-operator-default-configuration.yaml
gsutil rm -rf gs://$PROJECT/spilo/*
