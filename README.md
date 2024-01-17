# openshift-lab-scaling
templates for use with lab-scaling experiments

## Files

**Run this first**
* `setup.yaml` - creates the namespace, service account, and role binding to use the other manifests.

**Test stuff**
* `kube-burner-job-smoke-test.yaml` - a job to test the basic mechanics of running kube-burner in a pod.
* `kube-burner-job-basic.yaml` - a job with custom kube-burner image using the cluster-scaling workflow.
