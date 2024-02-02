# ms-scripter

this directory contains some tools for quickly creating machineset and machineautoscaler
manifests based on a set of instance types.

look at the configuration toml and the example template to see how it works, or try this:

```
./ms-scripter.py -c casmod-p2c1.toml -t aws-machineset-template.yaml > machinesets.yaml
```

```
./ma-scripter.py -c casmod-p2c1.toml > machineautoscalers.yaml
```
