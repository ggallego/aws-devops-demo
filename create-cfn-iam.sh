#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $codestardemo_iam_stackname."

aws cloudformation create-stack \
    --stack-name $codestardemo_iam_stackname \
    --capabilities CAPABILITY_IAM \
    --template-body file://cloudformation/iam.json
    
stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_iam_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_iam_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $codestardemo_iam_stackname."
