#!/bin/bash
RUID=$(kubectl get postgresql acid-minimal-cluster  -oyaml | grep uid | cut -d ':' -f 2 | xargs)

cat << EOF | kubectl create -f -
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: acid-restore-cluster
  namespace: default
spec:
  teamId: "ACID"
  volume:
    size: 1Gi
  numberOfInstances: 1
  postgresql:
    version: "11"
  clone:
    uid: "$RUID"
    cluster: "acid-minimal-cluster"
    timestamp: "2020-10-25T13:33:00+02:00"
EOF
