#!/bin/bash

echo "## Setting up karpenter"

echo "## Scaling down machine set"
oc scale machineset -n openshift-machine-api --replicas=0 $(oc get machineset -n openshift-machine-api -o jsonpath='{.items[2].metadata.name}')

echo "## Create subnet tags to Karpenter discover only private subnets to spin-up nodes"
# Get the cluster VPC from existing node sub#net
export AWS_REGION=${AWS_REGION:-$(aws configure get region)}
export REGION=$AWS_REGION
export CLUSTER_ID=$(oc get infrastructures cluster -o jsonpath='{.status.infrastructureName}')
export MACHINESET_NAME=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.name}')
export MACHINESET_SUBNET_NAME=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.subnet.filters[0].values[0]')

VPC_ID=$(aws ec2 describe-subnets --region $AWS_REGION --filters Name=tag:Name,Values=$MACHINESET_SUBNET_NAME --query 'Subnets[].VpcId' --output text)

# 1) Filter subnets only with "private" in the name
# 2) Apply the tag matching the NodeClass
aws ec2 create-tags --region $AWS_REGION --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
  --resources $(aws ec2 describe-subnets \
    --region $AWS_REGION \
    --filters Name=vpc-id,Values=$VPC_ID \
    | jq -r '.Subnets[] | [{"Id": .SubnetId, "Name": (.Tags[] | select(.Key=="Name").Value) }]' \
    | jq -r '.[] | select(.Name | contains("private")).Id'  | tr '\n' ' ')

echo "## Setup namespace and credentials"
LOCAL_FILE="${CLUSTER_DIR}/.base.yaml"
curl -o "$LOCAL_FILE" https://raw.githubusercontent.com/mtulio/mtulio.labs/lab-kube-scaling/labs/ocp-aws-scaling/deploy-karpenter/setup/base.yaml
oc apply -f "$LOCAL_FILE"

echo "## Deploy the csr-approver"
LOCAL_FILE="${CLUSTER_DIR}/.csr-approver.yaml"
curl -o "$LOCAL_FILE" https://raw.githubusercontent.com/mtulio/mtulio.labs/lab-kube-scaling/labs/ocp-aws-scaling/deploy-karpenter/setup/csr-approver.yaml
oc apply -f "$LOCAL_FILE"

echo "## Export Required variables" 
export KARPENTER_NAMESPACE=karpenter
export KARPENTER_VERSION=v0.33.1
export WORKER_PROFILE=$(oc get machineset -n openshift-machine-api $(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.name}') -o json | jq -r '.spec.template.spec.providerSpec.value.iamInstanceProfile.id')
export KUBE_ENDPOINT=$(oc get infrastructures cluster -o jsonpath='{.status.apiServerInternalURI}')

cat <<EOF
KARPENTER_NAMESPACE=$KARPENTER_NAMESPACE
KARPENTER_VERSION=$KARPENTER_VERSION
CLUSTER_NAME=$CLUSTER_NAME
WORKER_PROFILE=$WORKER_PROFILE
EOF

echo "## Provision the infra required by Karpenter"
# Based in https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.33.1/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml
curl -o "${CLUSTER_DIR}/karpenter-template.yaml" https://raw.githubusercontent.com/mtulio/mtulio.labs/lab-kube-scaling/labs/ocp-aws-scaling/deploy-karpenter/setup/cloudformation.yaml

aws cloudformation create-stack \
    --region "${AWS_REGION}" \
    --stack-name "karpenter-${CLUSTER_NAME}" \
    --template-body "file://${CLUSTER_DIR}/karpenter-template.yaml" \
    --parameters \
        "ParameterKey=ClusterName,ParameterValue=${CLUSTER_NAME}"

aws cloudformation wait stack-create-complete \
    --region ${AWS_REGION} \
    --stack-name karpenter-${CLUSTER_NAME}

echo "## Install Karpenter with helm"
helm upgrade --install --namespace karpenter \
  karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version $KARPENTER_VERSION \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "aws.defaultInstanceProfile=$WORKER_PROFILE" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set "settings.cluster-endpoint=$KUBE_ENDPOINT"

echo "## Patch the cluster to enable Karpenter"
#
# Patches
#

# 1) Remove custom SCC defined by karpenter inheriting from Namespace
oc patch deployment.apps/karpenter -n karpenter --type=json -p="[{'op': 'remove', 'path': '/spec/template/spec/containers/0/securityContext'}]"

# 2A) Mount volumes/creds created by CCO (CredentialsRequests)
oc set volume deployment.apps/karpenter --add -t secret -m /var/secrets/karpenter --secret-name=karpenter-aws-credentials --read-only=true

# 2B) Set env vars required to use custom credentials and OpenShift specifics
oc set env deployment.apps/karpenter LOG_LEVEL=debug AWS_REGION=$AWS_REGION AWS_SHARED_CREDENTIALS_FILE=/var/secrets/karpenter/credentials CLUSTER_ENDPOINT=$KUBE_ENDPOINT

# 3) Run karpenter on Control Plane
oc patch deployment.apps/karpenter --type=json -p '[{
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {"key":"node-role.kubernetes.io/master", "operator": "Exists", "effect": "NoSchedule"}
}]'

# 4) Fix RBAC allowing karpenter to create nodeClaims
# https://github.com/aws/karpenter-provider-aws/blob/main/charts/karpenter/templates/clusterrole-core.yaml#L52-L67
# {"level":"ERROR","time":"2024-01-30T21:13:12.667Z","logger":"controller","message":"Reconciler error","commit":"2dd7fdc","controller":"nodeclaim.lifecycle","controllerGroup":"karpenter.sh","controllerKind":"NodeClaim","NodeClaim":{"name":"default-nvpkv"},"namespace":"","name":"default-nvpkv","reconcileID":"1a1a3577-753b-424f-b70a-3f89a6d388ab","error":"syncing node, syncing node labels, nodes \"ip-10-0-33-137.ec2.internal\" is forbidden: cannot set blockOwnerDeletion if an ownerReference refers to a resource you can't set finalizers on: , <nil>"} 
oc patch clusterrole karpenter --type=json -p '[{
    "op": "add",
    "path": "/rules/-",
    "value": {"apiGroups":["karpenter.sh"], "resources": ["nodeclaims","nodeclaims/finalizers", "nodepools","nodepools/finalizers"], "verbs": ["create","update","delete","patch"]}
  }]'


echo "## Setup Karpenter for test variants"

INFRA_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
MACHINESET_SG_NAME=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.securityGroups[0].filters[0].values[0]')
MACHINESET_INSTANCE_PROFILE=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.iamInstanceProfile.id')
MACHINESET_AMI_ID=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.ami.id')
MACHINESET_USER_DATA_SECRET=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.userDataSecret.name')
MACHINESET_USER_DATA=$(oc get secret -n openshift-machine-api $MACHINESET_USER_DATA_SECRET -o jsonpath='{.data.userData}' | base64 -d)

TAG_NAME="${MACHINESET_NAME/"-$REGION"*}-karpenter"

# Installer does not set the SG Name 'as-is' defined in the MachineSet, so it need to filter by tag:Name
# and discover the ID

cat <<EOF
AWS_REGION=$REGION
INFRA_NAME=$INFRA_NAME
MACHINESET_NAME=$MACHINESET_NAME
MACHINESET_SUBNET_NAME=$MACHINESET_SUBNET_NAME
MACHINESET_SG_NAME=$MACHINESET_SG_NAME
MACHINESET_INSTANCE_PROFILE=$MACHINESET_INSTANCE_PROFILE
MACHINESET_AMI_ID=$MACHINESET_AMI_ID
MACHINESET_USER_DATA_SECRET=$MACHINESET_USER_DATA_SECRET
MACHINESET_USER_DATA=$MACHINESET_USER_DATA
TAG_NAME=$TAG_NAME
EOF


NODE_CLASS_NAME=default
NODE_CLASS_FILENAME="${CLUSTER_DIR}/karpenter-nodeClass-$NODE_CLASS_NAME.yaml"
echo "## Create Karpenter Node Class [$NODE_CLASS_NAME][$NODE_CLASS_FILENAME]"

cat << EOF > $NODE_CLASS_FILENAME
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: $NODE_CLASS_NAME
spec:
  amiFamily: Custom
  amiSelectorTerms:
  - id: "${MACHINESET_AMI_ID}"
  instanceProfile: "${MACHINESET_INSTANCE_PROFILE}"
  subnetSelectorTerms:
  - tags:
      kubernetes.io/cluster/${INFRA_NAME}: owned
      karpenter.sh/discovery: "$CLUSTER_NAME"
  securityGroupSelectorTerms:
  - tags:
      Name: "${MACHINESET_SG_NAME}"
  tags:
    Name: ${TAG_NAME}
    cluster_name: $CLUSTER_NAME
    Environment: autoscaler
  userData: |
    $MACHINESET_USER_DATA
EOF

echo "## Review and create"

# Check if all vars have been replaced in ./kpt-provisioner-m6.yaml
cat $NODE_CLASS_FILENAME

# Apply the config
oc create -f $NODE_CLASS_FILENAME

echo "## Karpenter setup for cluster [$CLUSTER_NAME] completed" 
