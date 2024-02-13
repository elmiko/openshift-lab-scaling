#!/bin/bash

mkdir -p ./data

LAB_BUCKET="s3://767398003706-sde-cur"
aws s3 sync "$LAB_BUCKET/curp/" "./data/"

PACKAGE_NAME="pandas"

if pip show $PACKAGE_NAME > /dev/null; then
    echo "$PACKAGE_NAME is already installed"
else
    echo "$PACKAGE_NAME is not installed. Installing..."
    pip install $PACKAGE_NAME
fi

./cost-per-cluster.py

aws s3 sync "./.output/cur/" "$LAB_BUCKET/cur/"

echo "done "