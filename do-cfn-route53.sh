#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $codestardemo_route53_stackname."

codedeploy_elb_beta="$(aws cloudformation describe-stacks --stack-name $codestardemo_asgfleets_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`BetaELBId`].OutputValue')"
codedeploy_elb_prod="$(aws cloudformation describe-stacks --stack-name $codestardemo_asgfleets_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ProdELBId`].OutputValue')"

aws cloudformation create-stack \
    --stack-name $codestardemo_route53_stackname \
    --template-body file://cloudformation/route53.json \
    --parameters ParameterKey=DBName,ParameterValue=$codestardemo_envname \
				 ParameterKey=BetaELBId,ParameterValue=$codedeploy_elb_beta \
                 ParameterKey=ProdELBId,ParameterValue=$codedeploy_elb_prod
    
stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_route53_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_route53_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $codestardemo_route53_stackname."
