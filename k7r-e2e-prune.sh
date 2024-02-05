#!/bin/bash

TAG_NAME="cluster_name"
TAG_VALE="$CLUSTER_NAME"

echo "## Done pruning cluster [$TAG_NAME=$TAG_VALUE]" 

echo "## Terminating instances" 
# Terminate EC2 instances
aws ec2 describe-instances --filters "Name=tag:$TAG_NAME,Values=$TAG_VALUE" --query 'Reservations[*].Instances[*].InstanceId' --output text | while read instanceId
do
    echo "Terminating instance: $instanceId"
    aws ec2 terminate-instances --instance-ids $instanceId
done

# Delete Load Balancers
echo "## Deleting load balancers" 
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text | while read loadBalancerArn
do
    echo "Deleting Load Balancer: $loadBalancerArn"
    aws elbv2 delete-load-balancer --load-balancer-arn $loadBalancerArn
done

# Delete Subnets
echo "## Deleting subnets" 
aws ec2 describe-subnets --filters "Name=tag:$TAG_NAME,Values=$TAG_VALUE" --query 'Subnets[*].SubnetId' --output text | while read subnetId
do
    echo "Deleting Subnet: $subnetId"
    aws ec2 delete-subnet --subnet-id $subnetId
done

# Delete Security Groups
echo "## Describe security groups" 
aws ec2 describe-security-groups --filters "Name=tag:$TAG_NAME,Values=$TAG_VALUE" --query 'SecurityGroups[*].GroupId' --output text | while read groupId
do
    echo "Deleting Security Group: $groupId"
    aws ec2 delete-security-group --group-id $groupId
done

# Delete VPCs
echo "## Delete VPCs" 
aws ec2 describe-vpcs --filters "Name=tag:$TAG_NAME,Values=$TAG_VALUE" --query 'Vpcs[*].VpcId' --output text | while read vpcId
do
    echo "Deleting VPC: $vpcId"
    aws ec2 delete-vpc --vpc-id $vpcId
done

echo "## Done pruning cluster [$TAG_NAME=$TAG_VALUE]" 
