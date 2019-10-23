#!/bin/bash

source ./config.sh

PROJECT=$(cat ID | xargs)

gsutil rm -rf gs://$BUCKET
gcloud -q projects delete $PROJECT
