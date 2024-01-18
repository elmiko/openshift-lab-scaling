# openshift-lab-scaling
templates for use with lab-scaling experiments

## Files

**Run this first**
* `setup.yaml` - creates the namespace, service account, and role binding to use the other manifests.

**Test stuff**
These run themselves, no changes needed
* `kube-burner-job-smoke-test.yaml` - a job to test the basic mechanics of running kube-burner in a pod.
* `kube-burner-job-basic.yaml` - a job with custom kube-burner image using the cluster-scaling workflow.

These are CronJobs and should be checked before running to ensure that the schedules are correct.
* `two-hour-scaling-test.yaml` - a series of 3 jobs that will run over the course of 2 hours, scaling the cluster out and in during the process.

**Tool to help**
* `pykb-runner` - this directory contains a wrapper script for executing serial kube-runner runs from within the cluster.
