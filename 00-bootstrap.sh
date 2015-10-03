#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE ... remove if you need to bootstrap!" 2>&1
    exit 1
fi

# ensure correct params was informed
if [ "$#" -ne 2 ]; then
    echo "Usage: $(basename $0) <envname> <keypairname>" >&2
    exit 1
fi

envname="$1"
if [ -z "$envname" ]; then
    echo "Usage: $(basename $0) <envname> <keyname>" >&2
    exit 1
fi

keyname="$2"
if [ -z "$keyname" ]; then
    echo "Usage: $(basename $0) <envname> <keyname>" >&2
    exit 1
fi

# ensure EC2 key pair exists
if [ -n "$keyname" ]; then
    if ! aws ec2 describe-key-pairs --key-names $keyname > /dev/null ; then
        echo "Fatal: $keyname doesn't exist" >&2
        exit 1
    fi
fi

# ensure S3 bucket exists
if [ -z "$AWS_ACCOUNT_ID" ]; then
    aws_account_id="$(curl --connect-timeout 1 --retry 0 -s http://169.254.169.254/latest/meta-data/iam/info | grep -o 'arn:aws:iam::[0-9]\+:' | cut -f 5 -d :)"
    if [ -z "$aws_account_id" ]; then
        aws_account_id="$(aws iam get-user --output=text --query 'User.Arn' | cut -f 5 -d :)"
    fi
    if [ -z "$aws_account_id" ]; then
        echo "Fatal: unable to determine AWS Account Id!" >&2
        echo "Your environment may not configured properly" >&2
        exit 1
    fi
    export AWS_ACCOUNT_ID="$aws_account_id"
fi

# generate jenkinsprovidername
jenkinsprovider_name="JP$(echo $envname | tr '[[:lower:]]' '[[:upper:]]')$(printf "%x" $(date +%s))"


touch "$ENVIRONMENT_FILE"
echo "export codestardemo_envname=$envname" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_keyname=$keyname" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_vpc_stackname=$envname-vpc" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_iam_stackname=$envname-iam" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_securitygroup_stackname=$envname-securitygroup" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_asgfleets_stackname=$envname-asgfleets" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_rds_stackname=$envname-rds" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_s3bucket=$envname-$AWS_ACCOUNT_ID" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_s3bucket_codepipeline_artifactstore=$envname-$AWS_ACCOUNT_ID"-codepipeline-artifactstore >> "$ENVIRONMENT_FILE"
echo "export codestardemo_jenkins_stackname=$envname-jenkins" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_jenkinsprovider_name=$jenkinsprovider_name" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_codedeploy_application=$envname" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_codedeploy_deploymentgroup_beta=beta" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_codedeploy_deploymentgroup_prod=prod" >> "$ENVIRONMENT_FILE"
echo "export codestardemo_codepipeline=$envname" >> "$ENVIRONMENT_FILE"

"$script_dir/create-cfn-vpc.sh"
"$script_dir/create-cfn-iam.sh"
"$script_dir/create-cfn-securitygroup.sh"
"$script_dir/create-cfn-asgfleets.sh"
"$script_dir/create-cfn-rds.sh"
"$script_dir/create-s3bucket.sh"
"$script_dir/create-cfn-jenkins.sh"
"$script_dir/create-codedeploy.sh"
"$script_dir/create-codepipeline.sh"
