#!/bin/bash

. ./config.sh

PROJECT="$CUSTOMER-$ID"

# Create project, set up billing and API, and a gs bucket
gcloud projects create $PROJECT
gcloud config set project $PROJECT
gcloud alpha billing projects link $PROJECT --billing-account=$BILLINGACCOUNT
gcloud services enable container.googleapis.com --project $PROJECT
gsutil mb -b on -l $REGION gs://$PROJECT
