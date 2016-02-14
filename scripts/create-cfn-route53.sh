#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating domain $awsdevopsdemo_route53_hostedzonename."

betafleet_public_dns="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_asgfleets_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`BetaPublicDns`].OutputValue')"
prodfleet_public_dns="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_asgfleets_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ProdPublicDns`].OutputValue')"

aws cloudformation create-stack \
    --stack-name $awsdevopsdemo_route53_stackname \
    --template-body file://cloudformation/route53.json \
    --parameters ParameterKey=HostedZoneName,ParameterValue=$awsdevopsdemo_route53_hostedzonename \
                 ParameterKey=BetaPublicDns,ParameterValue=$betafleet_public_dns \
                 ParameterKey=ProdPublicDns,ParameterValue=$prodfleet_public_dns

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $awsdevopsdemo_route53_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $awsdevopsdemo_route53_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $awsdevopsdemo_route53_stackname."
