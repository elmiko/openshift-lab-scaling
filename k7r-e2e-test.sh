#!/usr/bin/env bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export ENV_ID="k7r$RANDOM"
echo $ENV_ID > .env-id.txt

export CLUSTER_NAME="$ENV_ID"
export INSTALL_DIR="${DIR}/.install-dir/$CLUSTER_NAME"

# check if openshift-insall is not available
if ! command -v openshift-install &> /dev/null
then
    echo "openshift-install could not be found. Installing..."
    source ./install-openshift-install.sh
fi

echo "Creating new cluster [$ENV_ID]"
source ./create-cluster.aws-e2e.sh

echo "Checking cluster is accessible"
oc cluster-info

TEST_CASE=$1
if [ -n "$TEST_CASE" ]; then
    echo "Running test case $TEST_CASE"
    # Code for the case where the variable is set
else
    echo "No test case passed, running no test case"
    # Code for the case where the variable is not set or is empty
fi

echo "Destroying cluster [$ENV_ID]"
source ./destroy-cluster.e2e.sh