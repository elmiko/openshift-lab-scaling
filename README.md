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
