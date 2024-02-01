#!/usr/bin/env bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export ENV_ID="k7r$RANDOM"
export TEST_CASE="$1"

export CLUSTER_NAME="$ENV_ID"

echo "Running e2e test [$TEST_CASE] on [$ENV_ID]"
sleep 5

if ! command -v openshift-install &> /dev/null
then
    echo "openshift-install could not be found. Installing..."
    source ./install-openshift.sh
fi

echo "Creating new cluster [$ENV_ID]"
source ./create-cluster.aws-e2e.sh

echo "Checking cluster is accessible"
oc cluster-info


if [ -n "$TEST_CASE" ]; then
    echo "Running test case $TEST_CASE"
    # Code for the case where the variable is set
    TEST_SCRIPT="./k7r-e2e-$TEST_CASE.sh"
    if [ -x "$TEST_SCRIPT" ]; then
        echo "$TEST_SCRIPT found, executing..."
        source $TEST_SCRIPT
    else
        echo "$TEST_SCRIPT not found"
    fi
else
    echo "No test case passed, running no test case"
    # Code for the case where the variable is not set or is empty
fi

echo "Destroying cluster [$ENV_ID]"
source ./destroy-cluster.e2e.sh