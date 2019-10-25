#!/bin/bash

. ./config.sh
PROJECT="$CUSTOMER-$ID"
gsutil rm -rf gs://$PROJECT/spilo/*
gcloud projects delete $PROJECT
