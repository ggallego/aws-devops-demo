#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $codestardemo_rds_stackname."

rds_sg="$(aws cloudformation describe-stacks --stack-name $codestardemo_securitygroup_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`RDSSecurityGroup`].OutputValue')"
dbsubnet_id="$(aws cloudformation describe-stacks --stack-name $codestardemo_vpc_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`DBSubnetGroup`].OutputValue')"

aws cloudformation create-stack \
    --stack-name $codestardemo_rds_stackname \
    --template-body file://cloudformation/rds.json \
    --parameters ParameterKey=DBName,ParameterValue=$codestardemo_envname \
                 ParameterKey=RDSSecurityGroup,ParameterValue=$rds_sg \
                 ParameterKey=DBSubnetGroupName,ParameterValue=$dbsubnet_id

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_rds_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_rds_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $codestardemo_rds_stackname."
