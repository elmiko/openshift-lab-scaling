#!/bin/env python3
import logging
import subprocess


def main():
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting kube-burner runner")

    subprocess.run(["kube-burner", "ocp", "cluster-scaling", "--help"])



if __name__ == "__main__":
    main()
