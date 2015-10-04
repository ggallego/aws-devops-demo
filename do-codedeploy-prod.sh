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

echo "Executing deploy $codestardemo_codedeploy_application."

aws deploy create-deployment \
    --application-name $codestardemo_codedeploy_application \
    --s3-location bucket=$codestardemo_s3bucket,key=$s3_object_to_deploy,bundleType=zip \
    --deployment-group-name $codestardemo_codedeploy_deploymentgroup_prod \
    --deployment-config-name CodeDeployDefault.OneAtATime

echo "Executed deploy $codestardemo_codedeploy_application."