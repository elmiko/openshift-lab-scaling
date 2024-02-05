#!/usr/bin/env bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export TEST_CASE="$1"

if [ -z "$TEST_CASE" ]; then
    echo "## WARNING: no test case requested"
fi

export PREFIX="k7r"
export TIMESTAMP="$(date +%m%d%H%M)"
export TEST_CASE=${TEST_CASE:-"e2e"}
export ENV_ID="${PREFIX}${TIMESTAMP}${TEST_CASE}"

export CLUSTER_NAME="$ENV_ID"
export CLUSTER_DIR="./.output/.$CLUSTER_NAME"
export INSTALL_DIR="${INSTALL_DIR:-$CLUSTER_DIR/install-dir}"

echo "## Running e2e test [$TEST_CASE] on [$ENV_ID]"
mkdir -p "$CLUSTER_DIR"
sleep 5

echo "## Creating new cluster [$ENV_ID]"
source ./create-cluster.aws-e2e.sh | tee "${CLUSTER_DIR}/.create-cluster.log.txt"

echo "## Checking cluster is accessible"
oc cluster-info | tee "${CLUSTER_DIR}/.cluster-info.log.txt"

echo "## Setup karpeneter"
source ./setup-k7r.sh | tee "${CLUSTER_DIR}/.setup-k7r.log.txt"

if [ -n "$TEST_CASE" ]; then
    echo "## Running test case $TEST_CASE"
    # Code for the case where the variable is set
    TEST_SCRIPT="./k7r-e2e-$TEST_CASE.sh"
    if [ -x "$TEST_SCRIPT" ]; then
        echo "## $TEST_SCRIPT found, executing..."
        source $TEST_SCRIPT
    else
        echo "## $TEST_SCRIPT not found"
    fi
else
    echo "No test case passed, running no test case"
    # Code for the case where the variable is not set or is empty
fi

echo "## Gathering cluster data [$ENV_ID]"
source ./collect-cluster.e2e.sh | tee "${CLUSTER_DIR}/.collect-cluster.log.txt"

echo "## DEBUG [DELETE LATER]"
find . | tee "${CLUSTER_DIR}/.find.log.txt"

echo "## Destroying cluster [$ENV_ID]"
source ./destroy-cluster.e2e.sh | tee "${CLUSTER_DIR}/.destroy-cluster.log.txt" 

source ./k7r-e2e-prune.sh | tee "${CLUSTER_DIR}/.prune-cluster.log.txt"

echo "## Done e2e test case [$TEST_CASE] on [$ENV_ID]" | tee   "${CLUSTER_DIR}/.k7r-e2e-test-done.log.txt"
