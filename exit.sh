#!/bin/bash

. ./config.sh
PROJECT="$CUSTOMER-$ID"
gcloud projects delete $PROJECT
