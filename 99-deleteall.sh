#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo 'This will delete all codestardemos resources!'
echo
echo "Dump of environment.sh:"
cat $ENVIRONMENT_FILE
echo
read -p 'Press <ENTER> to continue ...'

echo deleting codedeploy...
"$script_dir/delete-codedeploy.sh"

echo deleting codepipeline...
"$script_dir/delete-codepipeline.sh"

echo deleting infrastructure stacks...
"$script_dir/delete-cfn-stacks.sh"

rm -f "$ENVIRONMENT_FILE"

