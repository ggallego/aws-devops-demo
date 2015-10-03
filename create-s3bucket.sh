#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $codestardemo_s3bucket."
aws s3 mb s3://$codestardemo_s3bucket || exit $?
aws s3api put-bucket-versioning \
    --bucket $codestardemo_s3bucket \
    --versioning-configuration "{\"Status\":\"Enabled\"}"

echo "Uploafing appdemo."
aws s3 cp appdemo/appfuse-v1.zip s3://$codestardemo_s3bucket/appdemo/appfuse-v1.zip
#aws s3 cp appdemo/appfuse-v1.zip s3://$codestardemo_s3bucket/appdemo/appfuse-v1-src.zip
#aws s3 cp appdemo/appfuse-v2.zip s3://$codestardemo_s3bucket/appdemo/appfuse-v2.zip
aws s3 cp appdemo/appfuse-v2.zip s3://$codestardemo_s3bucket/appdemo/appfuse-v2-src.zip
#aws s3 cp appdemo/appfuse-v3.zip s3://$codestardemo_s3bucket/appdemo/appfuse-v3.zip
#aws s3 cp appdemo/appfuse-v3.zip s3://$codestardemo_s3bucket/appdemo/appfuse-v3-src.zip

echo "Creating $codestardemo_s3bucket_codepipeline_artifactstore."
aws s3 mb s3://$codestardemo_s3bucket_codepipeline_artifactstore

echo "Created s3buckets"

