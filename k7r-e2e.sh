#!/bin/bash

echo "Running end-to-end test - case0 (dry run)"
./k7r-e2e-test.sh case0 | tee .case0.log.txt

echo "Running end-to-end test - phase1 - case 1"
./k7r-e2e-test.sh p1c1 | tee .p1c1.log.txt

echo "Running end-to-end test - phase1 - case 2"
./k7r-e2e-test.sh p1c2 | tee .p1c2

echo "Done e2e test"