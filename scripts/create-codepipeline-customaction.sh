#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating codepipeline customaction $awsdevopsdemo_codepipeline."

jenkins_ip="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_jenkins_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`JenkinsPublicIp`].OutputValue')"
jenkins_url="http://$jenkins_ip:8080"

generate_cli_json() {
    cat << _END_
{
    "category": "$1",
    "provider": "$awsdevopsdemo_jenkinsprovider_name",
    "version": "1",
    "settings": {
        "entityUrlTemplate": "$jenkins_url/job/{Config:ProjectName}",
        "executionUrlTemplate": "$jenkins_url/job/{Config:ProjectName}/{ExternalExecutionId}"
    },
    "configurationProperties": [
        {
            "name": "ProjectName",
            "required": true,
            "key": true,
            "secret": false,
            "queryable": true
        }
    ],
    "inputArtifactDetails": {
        "minimumCount": 0,
        "maximumCount": 5
    },
    "outputArtifactDetails": {
        "minimumCount": 0,
        "maximumCount": 5
    }
}
_END_
}

aws codepipeline create-custom-action-type --cli-input-json "$(generate_cli_json Build)"
#aws codepipeline create-custom-action-type --cli-input-json "$(generate_cli_json Test)"

echo "Created codepipeline customaction $awsdevopsdemo_codepipeline."
