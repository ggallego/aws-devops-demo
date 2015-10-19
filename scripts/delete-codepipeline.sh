#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

# CODEPIPELINE

echo "Deleting codepipeline $awsdevopsdemo_codepipeline."

aws codepipeline delete-pipeline --name $awsdevopsdemo_codepipeline

aws codepipeline delete-custom-action-type \
    --action-version 1 --category Build --provider $awsdevopsdemo_jenkinsprovider_name

#aws codepipeline delete-custom-action-type \
#    --action-version 1 --category Test --provider $awsdevopsdemo_jenkinsprovider_name

echo "Deleted codepipeline $awsdevopsdemo_codepipeline."
