#!/bin/bash

source ./config.sh

PROJECT=$(cat .PROJECT | xargs)
gcloud container clusters delete  $PROJECT --zone=$ZONE
gsutil rm -rf gs://$PROJECT/spilo/*
#gcloud -q projects delete $PROJECT
