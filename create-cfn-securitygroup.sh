#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $codestardemo_securitygroup_stackname."

vpc="$(aws cloudformation describe-stacks --stack-name $codestardemo_vpc_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue')"

aws cloudformation create-stack \
    --stack-name $codestardemo_securitygroup_stackname \
    --template-body file://cloudformation/securitygroup.json \
    --parameters ParameterKey=VPC,ParameterValue=$vpc

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_securitygroup_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_securitygroup_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $codestardemo_securitygroup_stackname."
