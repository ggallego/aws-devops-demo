#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

s3_object_to_deploy=$1

. $ENVIRONMENT_FILE

echo "Executing deploy $awsdevopsdemo_codedeploy_application."

aws deploy create-deployment \
    --application-name $awsdevopsdemo_codedeploy_application \
    --s3-location bucket=$awsdevopsdemo_s3bucket,key=$s3_object_to_deploy,bundleType=zip \
    --deployment-group-name $awsdevopsdemo_codedeploy_deploymentgroup_beta \
    --deployment-config-name CodeDeployDefault.OneAtATime

echo "Executed deploy $awsdevopsdemo_codedeploy_application."
