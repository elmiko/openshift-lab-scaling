#!/bin/bash
POOL_NAME=p1c2-m6xlarge-od-spot
POOL_CONFIG_FILE=./karpenter-${POOL_NAME}.yaml
POOL_CAPCITY_TYPES="\"on-demand\", \"spot\""
POOL_INSTANCE_FAMILY="\"m6i\""
CLUSTER_LIMIT_CPU="40"
CLUSTER_LIMIT_MEM="160Gi"

# Read for more info: https://karpenter.sh/docs/concepts/nodepools/
cat << EOF > ${POOL_CONFIG_FILE}
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: $POOL_NAME
spec:
  template:
    metadata:
      labels:
        Environment: karpenter
    spec:
      nodeClassRef:
        name: $NODE_CLASS_NAME

      # forcing to match m6i.xlarge (phase 1)
      requirements:
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: [$POOL_INSTANCE_FAMILY]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: [$POOL_CAPCITY_TYPES]
        - key: "karpenter.k8s.aws/instance-size"
          operator: In
          values: ["xlarge"]

  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 12h

  limits:
    cpu: "$CLUSTER_LIMIT_CPU"
    memory: $CLUSTER_LIMIT_MEM
  weight: 10
EOF

echo $POOL_CONFIG_FILE
oc create -f $POOL_CONFIG_FILE

echo "trigger test case"
oc apply -f https://raw.githubusercontent.com/elmiko/openshift-lab-scaling/devel/setup.yaml
oc apply -f https://raw.githubusercontent.com/elmiko/openshift-lab-scaling/devel/three-hour-scaling-test.yaml