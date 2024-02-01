#!/bin/bash


echo "Collect must-gather"
oc adm must-gather --dest-dir="$INSTALL_DIR/must-gather"

LAB_BUCKET=s3://767398003706-sde-cur
echo "Uploading"
aws s3 cp --recursive $INSTALL_DIR $LAB_BUCKET/clusters/$ENV_ID
