#!/bin/env python3
import argparse
import sys
import tomllib

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', required=True)
    parser.add_argument('-t', '--template', required=True)
    args = parser.parse_args()

    with open(args.config, 'rb') as f:
        config = tomllib.load(f)

    if not valid_config(config):
        sys.exit(1)

    with open(args.template) as f:
        template = f.read()

    output = ''

    for i in config['instance_types']:
        machineset_name = config['machineset_basename'] + i
        cluster_api_cluster = config['cluster_api_cluster']
        data = {
            'cluster_api_cluster': cluster_api_cluster,
            'machineset_name': machineset_name,
            'instance_type': i
        }
        data.update(config['provider'])
        output += template.format(**data)

    print(output)


def valid_config(config):
    if len(config.get('instance_types', [])) == 0:
        print("No instance types found in config")
        return False

    if not config.get('provider'):
        print("No provider section found in config")
        return False

    if not config.get('instance_type_mapping'):
        print("No instance type mapping found in config")
        return False

    return True


if __name__ == '__main__':
    main()
