#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")/scripts"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE ... remove if you need to bootstrap!" 2>&1
    exit 1
fi

# ensure correct params was informed
if [ "$#" -ne 3 ]; then
    echo "Usage: $(basename $0) <envname> <keypairname> <passwd>" >&2
    echo "       - <envname: prefix to new aws resource names and tags created in your account>" >&2
    echo "       - <keypairname: name of your existing keypair on virginia region>" >&2
    echo "       - <passwd: password for the created rds and jenkins instances>" >&2
    exit 1
fi

# the name of the 'demo environment'
envname="$1"
if [ -z "$envname" ]; then
    echo "Usage: $(basename $0) <envname> <keypairname> <passwd>" >&2
    echo "       - <envname: prefix to new aws resource names and tags created in your account>" >&2
    echo "       - <keypairname: name of your existing keypair on virginia region>" >&2
    echo "       - <passwd: password for the created rds and jenkins instances>" >&2
    exit 1
fi

# use this aws keypair name to setup the demo environment
keyname="$2"
if [ -z "$keyname" ]; then
    echo "Usage: $(basename $0) <envname> <keypairname> <passwd>" >&2
    echo "       - <envname: prefix to new aws resource names and tags created in your account>" >&2
    echo "       - <keypairname: name of your existing keypair on virginia region>" >&2
    echo "       - <passwd: password for the created rds and jenkins instances>" >&2
    exit 1
fi

# ensure EC2 key pair exists
if [ -n "$keyname" ]; then
    if ! aws ec2 describe-key-pairs --key-names $keyname > /dev/null ; then
        echo "Fatal: $keyname doesn't exist" >&2
        exit 1
    fi
fi

# password to use everywhere (rds, jenkins, ...)
passwd="$3"
if [ -z "$passwd" ]; then
    echo "Usage: $(basename $0) <envname> <keypairname> <passwd>" >&2
    echo "       - <envname: prefix to new aws resource names and tags created in your account>" >&2
    echo "       - <keypairname: name of your existing keypair on virginia region>" >&2
    echo "       - <passwd: password for the created rds and jenkins instances>" >&2
    exit 1
fi

# if it is specified just set it on current_environment.sh, but do not set it on route53 automatically (yet)
hostedzonename="$4"
if [ -n "$hostedzonename" ]; then
    hostedzonename=""
fi

# github oauthtoken, useful to create github pipeline integration
github_oauthtoken="$5"
if [ -n "$github_oauthtoken" ]; then
    github_oauthtoken="undefined"
fi

# determine account ID (on ec2, then on your home computer)
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

# generate jenkinsmasterpasswdhash_entry
jenkinsmasterpasswdhash_entry="$(echo -n '$passwd{awsdevopsdemo}' | shasum -a 256 | cut -d' ' -f1)"


touch "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_envname=$envname" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_keyname=$keyname" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_passwd=$passwd" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_route53_hostedzonename=$hostedzonename" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_github_oauthtoken=$github_oauthtoken" >> "$ENVIRONMENT_FILE"

echo "export awsdevopsdemo_vpc_stackname=$envname-vpc" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_iam_stackname=$envname-iam" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_securitygroup_stackname=$envname-securitygroup" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_asgfleets_stackname=$envname-asgfleets" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_rds_stackname=$envname-rds" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_s3bucket=$envname-$AWS_ACCOUNT_ID" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_s3bucket_codepipeline_artifactstore=$envname-$AWS_ACCOUNT_ID"-codepipeline-artifactstore >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_jenkins_stackname=$envname-jenkins" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_jenkinsprovider_name=$jenkinsprovider_name" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_jenkinsmasterpasswdhash_entry=$jenkinsmasterpasswdhash_entry" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_codedeploy_application=$envname" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_codedeploy_deploymentgroup_beta=beta" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_codedeploy_deploymentgroup_prod=prod" >> "$ENVIRONMENT_FILE"
echo "export awsdevopsdemo_codepipeline=$envname" >> "$ENVIRONMENT_FILE"

"$script_dir/create-cfn-vpc.sh"
"$script_dir/create-cfn-iam.sh"
"$script_dir/create-cfn-securitygroup.sh"
"$script_dir/create-cfn-asgfleets.sh"
"$script_dir/create-cfn-rds.sh"
"$script_dir/create-s3bucket.sh"
"$script_dir/create-cfn-jenkins.sh"
"$script_dir/create-codedeploy.sh"
"$script_dir/create-codepipeline-customaction.sh"
"$script_dir/create-codepipeline.sh"
