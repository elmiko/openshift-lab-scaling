#!/bin/bash

mkdir -p ./data
<<<<<<< HEAD

LAB_BUCKET=s3://767398003706-sde-cur
aws s3 sync $LAB_BUCKET ./data

PACKAGE_NAME="pandas"

if pip show $PACKAGE_NAME > /dev/null; then
    echo "$PACKAGE_NAME is already installed"
else
    echo "$PACKAGE_NAME is not installed. Installing..."
    pip install $PACKAGE_NAME
fi

=======
aws sync s3://767398003706-sde-cur ./data
>>>>>>> upstream/devel
./cost-per-cluster.py

echo "done"