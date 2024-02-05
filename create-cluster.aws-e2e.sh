#!/bin/bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export PREFIX=${PREFIX:-'k7r'}
export TIMESTAMP=${TIMESTAMP:-$(date +%m%d%H%M)}
export TEST_CASE=${TEST_CASE:-"debug"}
export ENV_ID="${PREFIX}${TIMESTAMP}${TEST_CASE}"

export CLUSTER_NAME="$ENV_ID"
export CLUSTER_DIR="./.output/.$CLUSTER_NAME"

export VERSION=${VERSION:-4.14.10}

PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-latest.json"
RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64
SSH_PUB_KEY_FILE="$HOME/.ssh/id_rsa.pub"

export CLUSTER_BASE_DOMAIN="${CLUSTER_BASE_DOMAIN:-lab-scaling.devcluster.openshift.com}"
export AWS_REGION="${AWS_REGION:-$(aws configure get region)}"
export REGION="$AWS_REGION"

export PULL_SECRET=${PULL_SECRET:-$(cat $PULL_SECRET_FILE)}
export SSH_KEY=${SSH_KEY:-$(cat $SSH_PUB_KEY_FILE)}

export INSTALL_DIR=${INSTALL_DIR:-$CLUSTER_DIR/install-dir}
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR

echo "## Creating ${INSTALL_DIR}/install-config.yaml"
mkdir -p ${INSTALL_DIR}
envsubst < install-config.aws-e2e.env.yaml > ${INSTALL_DIR}/install-config.yaml 
cp ${INSTALL_DIR}/install-config.yaml ${INSTALL_DIR}/install-config.bkp.yaml

echo "## Verify install-config"
cat ${INSTALL_DIR}/install-config.yaml

echo "## Creating cluster [$CLUSTER_NAME] from [$INSTALL_DIR]"
LOG_LEVEL="debug"
openshift-install create cluster --dir=$INSTALL_DIR --log-level="$LOG_LEVEL"
if [ $? -ne 0 ]; then
    echo "## Create cluster [$CLUSTER_NAME] failed, exiting."
    exit 1
fi

echo "## Updating kubeconfig"
if [ -f "$HOME/.kube/config" ]; then
    echo "Backing up existing kubeconfig"
    mv "$HOME/.kube/config" "$HOME/.kube/config.bak.$(date +%Y%m%d%H%M%S)"
fi
mkdir -p "$HOME/.kube"
cp "${INSTALL_DIR}/auth/kubeconfig" "$HOME/.kube/config"

echo "## Checking cluster API access"
if kubectl cluster-info; then
  echo "Kubernetes API seems OK"
else
  echo "Kubernetes API is not responding"
fi

echo "## Cluster is ready!"
