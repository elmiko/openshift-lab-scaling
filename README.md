# openshift-lab-scaling
templates for use with lab-scaling experiments

## Files

**Run this first**
* `setup.yaml` - creates the namespace, service account, and role binding to use the other manifests.

**Test stuff**

These tests just run the kube-burner to make sure that things are working properly.
* `kube-burner-job-smoke-test.yaml` - a job to test the basic mechanics of running kube-burner in a pod.
* `kube-burner-job-basic.yaml` - a job with custom kube-burner image using the cluster-scaling workflow.

These tests will invoke the pykb-runner to run a series of kube-burner tests.
* `three-hour-scaling-test.yaml` - deploys test workloads that will grow and shrink the cluster.

**Tool to help**
* `pykb-runner` - this directory contains a wrapper script for executing serial kube-runner runs from within the cluster.

## End to End testing

The `k7r-e2e.sh` script launches the entire testing process. It creates the cluster, sets up karpenter, runs the tests, collect artifacts and terminates the cluster. All scripts and configurations used in this workflow are marked with the "e2e" extension.

## GitPod support

If you launch this repository on https://gitpod.io/#https://github.com/elmiko/openshift-lab-scaling.git it will be provisioned with all necessary tools and libraries installed, ready for development. (see `.gitpod.yml` and `.gitpod.Dockerfile`)