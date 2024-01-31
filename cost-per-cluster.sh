#!/bin/bash

mkdir -p ./data
aws sync s3://767398003706-sde-cur ./data
./cost-per-cluster.py

echo "done"