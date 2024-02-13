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
export LOGS_DIR="${CLUSTER_DIR}/logs"
export INSTALL_DIR="${INSTALL_DIR:-$CLUSTER_DIR/install-dir}"

echo "## Running e2e test [$TEST_CASE] on [$ENV_ID]"
mkdir -p "$CLUSTER_DIR"
mkdir -p "$LOGS_DIR"
sleep 5

echo "## Creating new cluster [$ENV_ID]"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-create-cluster.log.txt"
source ./create-cluster.aws-e2e.sh | tee "$LOG_FILE"

echo "## Checking cluster is accessible"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-cluster-info.log.txt"
oc cluster-info | tee "${LOG_FILE}"

echo "## Setup karpeneter"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-setup-k7r.log.txt"
source ./setup-k7r.sh | tee "${LOG_FILE}"

if [ -n "$TEST_CASE" ]; then
    echo "## Running test case $TEST_CASE"
    # Code for the case where the variable is set
    TEST_SCRIPT="./k7r-e2e-$TEST_CASE.sh"
    if [ -x "$TEST_SCRIPT" ]; then
        echo "## $TEST_SCRIPT found, executing..."
        LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-test-case.log.txt"
        source $TEST_SCRIPT |  tee "${LOG_FILE}" 
    else
        LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-test-not-found.log.txt"
        echo "## $TEST_SCRIPT not found" |  tee "${LOG_FILE}" 
    fi
else
    echo "No test case passed, running no test case"
    # Code for the case where the variable is not set or is empty
fi

echo "## Gathering cluster data [$ENV_ID]"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-collect-cluster.log.txt"
source ./collect-cluster.e2e.sh | tee "${LOG_FILE}"

echo "## List FS (debug)"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-find.log.txt"
find . | tee "${LOG_FILE}"

echo "## Destroying cluster [$ENV_ID]"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-destroy-cluster.log.txt"
source ./destroy-cluster.e2e.sh | tee "${CLUSTER_DIR}/" 

echo "## Prune environment [$ENV_ID]"
LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-prune-cluster.log.txt"
source ./k7r-e2e-prune.sh | tee "${CLUSTER_DIR}/"

LOG_FILE="${LOGS_DIR}/.$(date +%Y%m%d%H%M%S)-k7r-e2e-test-done.log.txt"
echo "## Done e2e test case [$TEST_CASE] on [$ENV_ID]" | tee "$LOG_FILE"

