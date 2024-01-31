#!/bin/bash

echo "Running end-to-end test - case0"
./k7r-e2e-test.sh case0 | tee case0.log.txt

echo "Running end-to-end test - case1"
./k7r-e2e-test.sh case1 | tee case1.log.txt

echo "Done e2e test"