#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating codedeploy $codestardemo_codedeploy_application."

codedeploy_rolearn="$(aws cloudformation describe-stacks --stack-name $codestardemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`CodeDeployServiceRoleARN`].OutputValue')"
codedeploy_asg_beta="$(aws cloudformation describe-stacks --stack-name $codestardemo_asgfleets_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`BetaASGId`].OutputValue')"
codedeploy_asg_prod="$(aws cloudformation describe-stacks --stack-name $codestardemo_asgfleets_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ProdASGId`].OutputValue')"

aws deploy create-application \
    --application-name $codestardemo_codedeploy_application

aws deploy create-deployment-group \
  --application-name $codestardemo_codedeploy_application \
  --deployment-group-name $codestardemo_codedeploy_deploymentgroup_beta \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --auto-scaling-groups $codedeploy_asg_beta \
  --service-role-arn $codedeploy_rolearn

aws deploy create-deployment-group \
  --application-name $codestardemo_codedeploy_application \
  --deployment-group-name $codestardemo_codedeploy_deploymentgroup_prod \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --auto-scaling-groups $codedeploy_asg_prod \
  --service-role-arn $codedeploy_rolearn

echo "Created codedeploy $codestardemo_codedeploy_application."
