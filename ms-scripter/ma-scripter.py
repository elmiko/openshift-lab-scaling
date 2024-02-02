#!/bin/env python3
import argparse
import sys
import tomllib

template = '''---
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "worker-{machineset_name}"
  namespace: "openshift-machine-api"
spec:
  minReplicas: 0
  maxReplicas: 12
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: {machineset_name}
'''

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', required=True)
    args = parser.parse_args()

    with open(args.config, 'rb') as f:
        config = tomllib.load(f)

    if not valid_config(config):
        sys.exit(1)

    output = ''

    for i in config['instance_types']:
        machineset_name = config['machineset_basename'] + i
        output += template.format(machineset_name=machineset_name)

    print(output)


def valid_config(config):
    if len(config.get('instance_types', [])) == 0:
        print("No instance types found in config")
        return False

    return True


if __name__ == '__main__':
    main()

