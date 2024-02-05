#!/bin/bash

echo "## Collecting cluter [$CLUSTER_NAME]"

echo "## Collect must-gather to $INSTALL_DIR/must-gather"
oc adm must-gather --dest-dir="$INSTALL_DIR/must-gather"

LAB_BUCKET=s3://767398003706-sde-cur
echo "## Uploading all output"
aws s3 cp --recursive "$CLUSTER_DIR" "$LAB_BUCKET/output/$CLUSTER_NAME"

echo "## Done collecting cluster [$CLUSTER_NAME]"
