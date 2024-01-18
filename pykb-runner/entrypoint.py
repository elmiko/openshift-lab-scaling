#!/bin/env python3
import logging
import subprocess
import sys
import yaml


def main():
    logging.basicConfig(level=logging.INFO)
    logging.info("Starting kube-burner runner")

    try:
        raw = open("/etc/pykb-runner/config.yaml").read()
        data = yaml.load(raw, Loader=yaml.Loader)
    except Exception as ex:
        logging.error("unable to read configuration data")
        raise ex
    logging.info("loaded configuration")

    for i, r in enumerate(data.get("runs", [])):
        iterations = r.get("iterations")
        churn_duration = r.get("churn-duration")
        churn_delay = r.get("churn-delay")

        if not iterations or not churn_duration or not churn_delay:
            logging.error(f"run {i} misconfigured, check configuration data")
            sys.exit(1)

        kb_args = [f"--iterations={iterations}",
                   f"--churn-duration={churn_duration}",
                   f"--churn-delay={churn_delay}",
                   ]
        kb_cmd = ["kube-burner", "ocp", "cluster-scaling"]
        logging.info(f"Running command {kb_cmd + kb_args}")
        subprocess.run(kb_cmd + kb_args)


if __name__ == "__main__":
    main()
