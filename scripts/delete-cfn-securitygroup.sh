#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Deleting $awsdevopsdemo_securitygroup_stackname."

aws cloudformation delete-stack \
    --stack-name "$awsdevopsdemo_securitygroup_stackname"

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $awsdevopsdemo_securitygroup_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $awsdevopsdemo_securitygroup_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Deleted $awsdevopsdemo_securitygroup_stackname."
