#!/bin/bash

PROJECT=$(cat .PROJECT | xargs)
gsutil rm -rf gs://$PROJECT
gcloud -q projects delete $PROJECT
