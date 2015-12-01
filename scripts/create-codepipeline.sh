#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating codepipeline $awsdevopsdemo_codepipeline."

codepipeline_rolearn="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`CodePipelineTrustRoleARN`].OutputValue')"

pipeline_json=$(mktemp /tmp/$awsdevopsdemo_envname-pipeline.json.XXXXX)

pipeline_file="$1"
if [ -z "$pipeline_file" ]; then
  pipeline_file="$script_dir/../codepipeline/pipeline-ghsource-buildandtest-beta-ghostinspector-prod.json"
  #pipeline_file="$script_dir/../codepipeline/pipeline-ghsource-buildandtest-beta-prod.json"
  #pipeline_file="$script_dir/../codepipeline/pipeline-s3binary-beta-prod.json"
  #pipeline_file="$script_dir/../codepipeline/pipeline-s3source-buildandtest-beta-prod.json"
fi
cp "$pipeline_file" $pipeline_json

sed s/CODEPIPELINE_NAME_PLACEHOLDER/$awsdevopsdemo_codepipeline/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_JENKINSPROVIDER_PLACEHOLDER/$awsdevopsdemo_jenkinsprovider_name/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s,CODEPIPELINE_ROLEARN_PLACEHOLDER,$codepipeline_rolearn,g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_GITHUB_OAUTHTOKEN/$awsdevopsdemo_github_oauthtoken/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_S3BUCKET_PLACEHOLDER/$awsdevopsdemo_s3bucket/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json
sed s/CODEPIPELINE_S3BUCKET_CODEPIPELINE_ARTIFACTSTORE_PLACEHOLDER/$awsdevopsdemo_s3bucket_codepipeline_artifactstore/g $pipeline_json > $pipeline_json.new && mv $pipeline_json.new $pipeline_json

aws codepipeline create-pipeline \
    --pipeline file://$pipeline_json || exit $?

if [ "$pipeline_file" == "$script_dir/../codepipeline/pipeline-ghsource-buildandtest-beta-ghostinspector-prod.json" ]; then
    aws codepipeline disable-stage-transition \
        --pipeline-name $awsdevopsdemo_codepipeline \
        --stage-name Acceptance \
        --transition-type Inbound \
        --reason "Need configure ghostinspector first"
fi

rm -f $pipeline_json

echo "Created codepipeline $awsdevopsdemo_codepipeline."
