#!/bin/bash

CUSTOMER="rl"
ID=$(date +%s | md5sum | cut -b 1-8 | xargs)
BILLINGACCOUNT="0183FE-3C29B7-21A890"
PROJECT="$CUSTOMER-$ID"
REGION="europe-north1"
ZONE="europe-north1-a"
CLUSTER="$PROJECT"
