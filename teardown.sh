#!/bin/bash

gcloud container clusters delete rl-poc --zone=europe-north1-a
gsutil rm -rf gs://rl-poc/spilo/*
