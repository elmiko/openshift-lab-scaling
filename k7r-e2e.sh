#!/bin/bash
#./k7r-e2e.sh | tee ./.k7r-e2e.log.txt
export PATH=$DIR:$PATH
if ! command -v openshift-install &> /dev/null
then
    echo "## openshift-install could not be found. Installing..."
    source ./install-openshift.sh
fi

echo "## Running end-to-end test - dry run"
./k7r-e2e-test.sh dryrun 

echo " ## Running end-to-end test - phase1 - case 1"
./k7r-e2e-test.sh p1c1

echo "## Running end-to-end test - phase1 - case 2"
./k7r-e2e-test.sh p1c2

echo "## Done e2e test workflow"
