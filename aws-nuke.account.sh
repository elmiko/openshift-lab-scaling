#!/bin/bash

aws-nuke -c ./aws-nuke.account.yaml --no-dry-run --force --force-sleep 3 | tee .aws-nuke.log.txt
