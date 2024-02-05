#!/bin/bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Destroying cluster [$INSTALL_DIR]"
openshift-install destroy cluster --dir="$INSTALL_DIR" --log-level=debug
