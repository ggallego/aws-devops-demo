#!/usr/bin/env bash

stack_name="$1"
stack_status='UNKNOWN_IN_PROGRESS'

echo -n "Waiting $stack_name to finish." >&2
while [[ $stack_status =~ IN_PROGRESS$ ]]; do
    sleep 5
    stack_status="$(aws cloudformation describe-stacks --stack-name "$1" --output text --query 'Stacks[0].StackStatus')"
    echo -n . >&2
done
echo ""
echo "Finished $stack_name."

# if status is failed or we'd rolled back, assume bad things happened
if [[ $stack_status =~ _FAILED$ ]] || [[ $stack_status =~ ROLLBACK ]]; then
    exit 1
fi
exit 0
