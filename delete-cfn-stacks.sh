#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

### JENKINS

aws cloudformation delete-stack \
    --stack-name "$codestardemo_jenkins_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_jenkins_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_jenkins_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

### S3BUCKET

# pum!

### RDS

aws cloudformation delete-stack \
    --stack-name "$codestardemo_rds_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_rds_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_rds_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

### ASG FLEETS

aws cloudformation delete-stack \
    --stack-name "$codestardemo_asgfleets_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_asgfleets_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_asgfleets_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

### SECURITY GROUP

aws cloudformation delete-stack \
    --stack-name "$codestardemo_securitygroup_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_securitygroup_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_securitygroup_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

### IAM

aws cloudformation delete-stack \
    --stack-name "$codestardemo_iam_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_iam_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_iam_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

### VPC

aws cloudformation delete-stack \
    --stack-name "$codestardemo_vpc_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_vpc_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_vpc_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi
