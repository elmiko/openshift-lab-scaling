#!/usr/bin/env bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export TEST_CASE="$1"

if [ -z "$TEST_CASE" ]; then
    echo "**** WARNING: no test case requested"
fi

export PREFIX="k7r"
export TIMESTAMP="$(date +%y%m%d%H%M)"
export CLASSIFIER=${TEST_CASE:-"e2e"}
export ENV_ID="$PREFIX_$TIMESTAMP_$CLASSIFIER"

export CLUSTER_NAME="$ENV_ID"
export CLUSTER_DIR="./.$CLUSTER_NAME"

echo "**** Running e2e test [$TEST_CASE] on [$ENV_ID]"
mkdir -p 
sleep 5

echo "**** Creating new cluster [$ENV_ID]"
source ./create-cluster.aws-e2e.sh

echo "**** Checking cluster is accessible"
oc cluster-info

echo "**** Setup karpeneter"
source ./setup-k7r.sh

if [ -n "$TEST_CASE" ]; then
    echo "**** Running test case $TEST_CASE"
    # Code for the case where the variable is set
    TEST_SCRIPT="./k7r-e2e-$TEST_CASE.sh"
    if [ -x "$TEST_SCRIPT" ]; then
        echo "**** $TEST_SCRIPT found, executing..."
        source $TEST_SCRIPT
    else
        echo "**** $TEST_SCRIPT not found"
    fi
else
    echo "No test case passed, running no test case"
    # Code for the case where the variable is not set or is empty
fi

echo "**** Gathering cluster data [$ENV_ID]"
source ./collect-cluster.e2e.sh

echo "**** DEBUG [DELETE LATER]"
find .

echo "**** Destroying cluster [$ENV_ID]"
source ./destroy-cluster.e2e.sh

echo "**** Done e2e test case [$TEST_CASE] on [$ENV_ID]"