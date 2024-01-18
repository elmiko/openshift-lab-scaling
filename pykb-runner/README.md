# pykb-runner

This directory contains artifacts to create a kube-burner runner that
will run a series of tests in serial fashion, reading configuration
data from a configmap.

## configuration data

The configuration file for pykb-runner is `/etc/pykb-runner/config.yaml`
and it has the following format:

```yaml
runs:
  - iterations: 1
    churn-duration: 1h
    churn-delay: 20m
  - iterations: 4
    churn-duration: 30m
    churn-delay: 10m
```
