#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating codepipeline $codestardemo_codepipeline."

jenkins_ip="$(aws cloudformation describe-stacks --stack-name $codestardemo_jenkins_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`PublicIp`].OutputValue')"
codepipeline_rolearn="$(aws cloudformation describe-stacks --stack-name $codestardemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`CodePipelineTrustRoleARN`].OutputValue')"
jenkins_url="http://$jenkins_ip:8080"

generate_cli_json() {
    cat << _END_
{
    "category": "$1",
    "provider": "$codestardemo_jenkinsprovider_name",
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

pipeline_json=$(mktemp /tmp/$codestardemo_envname-pipeline.json.XXXXX)
cp "$script_dir/codepipeline/pipeline-codedeploy.json" $pipeline_json

sed s/CODEPIPELINE_NAME_PLACEHOLDER/$codestardemo_codepipeline/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_JENKINSPROVIDER_PLACEHOLDER/$codestardemo_jenkinsprovider_name/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s,CODEPIPELINE_ROLEARN_PLACEHOLDER,$codepipeline_rolearn,g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_S3BUCKET_PLACEHOLDER/$codestardemo_s3bucket/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_S3BUCKET_CODEPIPELINE_ARTIFACTSTORE_PLACEHOLDER/$codestardemo_s3bucket_codepipeline_artifactstore/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json

aws codepipeline create-pipeline --pipeline file://$pipeline_json || exit $?

rm -f $pipeline_json

echo "Created codepipeline $codestardemo_codepipeline."
