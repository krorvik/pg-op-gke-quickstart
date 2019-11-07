#!/bin/bash

. ./config.sh
PROJECT="$CUSTOMER-$ID"

gcloud container clusters delete finn-poc --zone=$ZONE
gsutil rm -rf gs://$PROJECT/spilo/*
