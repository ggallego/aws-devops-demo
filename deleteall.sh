#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")/scripts"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo 'This will delete all awsdevopsdemo resources!'
echo
echo "Dump of environment.sh:"
cat $ENVIRONMENT_FILE
echo
read -p 'Press <ENTER> to continue ...'

"$script_dir/delete-codedeploy.sh"
"$script_dir/delete-codepipeline.sh"
"$script_dir/delete-cfn-jenkins.sh"
"$script_dir/delete-s3bucket.sh"
"$script_dir/delete-cfn-rds.sh"
"$script_dir/delete-cfn-asgfleets.sh"
"$script_dir/delete-cfn-securitygroup.sh"
"$script_dir/delete-cfn-iam.sh"
"$script_dir/delete-cfn-vpc.sh"

rm -f "$ENVIRONMENT_FILE"

