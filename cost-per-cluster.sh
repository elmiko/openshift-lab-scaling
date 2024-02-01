#!/bin/bash

mkdir -p ./data
aws s3 sync s3://767398003706-sde-cur ./data

PACKAGE_NAME="pandas"

if pip show $PACKAGE_NAME > /dev/null; then
    echo "$PACKAGE_NAME is already installed"
else
    echo "$PACKAGE_NAME is not installed. Installing..."
    pip install $PACKAGE_NAME
fi

./cost-per-cluster.py

echo "done"