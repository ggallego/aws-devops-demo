#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $awsdevopsdemo_asgfleets_stackname."

subnet_id="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_vpc_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue')"
instance_profile="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceProfile`].OutputValue')"
instance_role="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceRole`].OutputValue')"
instance_sg="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_securitygroup_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceSecurityGroup`].OutputValue')"
elb_sg="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_securitygroup_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ELBSecurityGroup`].OutputValue')"

aws cloudformation create-stack \
    --stack-name $awsdevopsdemo_asgfleets_stackname \
    --template-body file://cloudformation/asgfleets.json \
    --parameters ParameterKey=IamInstanceProfile,ParameterValue=$instance_profile \
        ParameterKey=KeyName,ParameterValue=$awsdevopsdemo_keyname \
        ParameterKey=SubnetId,ParameterValue=$subnet_id \
        ParameterKey=InstanceSecurityGroup,ParameterValue=$instance_sg \
        ParameterKey=ELBSecurityGroup,ParameterValue=$elb_sg

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $awsdevopsdemo_asgfleets_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $awsdevopsdemo_asgfleets_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $awsdevopsdemo_asgfleets_stackname."
