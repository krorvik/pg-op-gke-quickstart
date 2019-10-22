#!/bin/bash

PROJECT=$(cat ID | xargs)

gcloud -q projects delete $PROJECT
# not needed as above will wipe it
#gcloud -q container clusters delete $CLUSTER
gsutil rm -rf gs://$PROJECT 

