#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Deleting s3bucket $awsdevopsdemo_s3bucket."

if aws s3 ls s3://$awsdevopsdemo_s3bucket > /dev/null 2> /dev/null; then
    aws s3api put-bucket-versioning \
        --bucket $awsdevopsdemo_s3bucket \
        --versioning-configuration "{\"Status\":\"Suspended\"}"

    aws s3api list-object-versions \
        --bucket $awsdevopsdemo_s3bucket \
        --output text \
        | grep -E "^VERSIONS" \
        | awk '{print "aws s3api delete-object --bucket $awsdevopsdemo_s3bucket --key "$4" --version-id "$8";"}' \
        | sh

    aws s3api list-object-versions \
        --bucket $awsdevopsdemo_s3bucket \
        --output text \
        | grep -E "^DELETEMARKERS" \
        | awk '{print "aws s3api delete-object --bucket $awsdevopsdemo_s3bucket --key "$3" --version-id "$5";"}' \
        | sh

       aws s3 rb --force s3://$awsdevopsdemo_s3bucket
fi

echo "Deleting s3bucket $awsdevopsdemo_s3bucket_codepipeline_artifactstore."

if aws s3 ls s3://$awsdevopsdemo_s3bucket_codepipeline_artifactstore > /dev/null 2> /dev/null; then
    aws s3 rb --force s3://$awsdevopsdemo_s3bucket_codepipeline_artifactstore
fi
echo "Deleted s3buckets."
