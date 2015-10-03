#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $codestardemo_jenkins_stackname."

vpc="$(aws cloudformation describe-stacks --stack-name $codestardemo_vpc_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue')"
subnet_id="$(aws cloudformation describe-stacks --stack-name $codestardemo_vpc_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue')"
instance_profile="$(aws cloudformation describe-stacks --stack-name $codestardemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceProfile`].OutputValue')"
instance_role="$(aws cloudformation describe-stacks --stack-name $codestardemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceRole`].OutputValue')"
instance_sg="$(aws cloudformation describe-stacks --stack-name $codestardemo_securitygroup_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceSecurityGroup`].OutputValue')"
rdstest_dbname="$(aws cloudformation describe-stacks --stack-name $codestardemo_rds_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`RDSTestDBName`].OutputValue')"
rdstest_dbhost="$(aws cloudformation describe-stacks --stack-name $codestardemo_rds_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`RDSTestDBHost`].OutputValue')"

config_dir="$script_dir/jenkins"
temp_dir=$(mktemp -d /tmp/$codestardemo_envname.XXXXX)
jobconfigs_tarball="$codestardemo_jenkins_stackname/jobconfigs-$(date +%s).tgz"

cp -r $config_dir/* $temp_dir/
pushd $temp_dir > /dev/null
for f in */config.xml; do
    sed s/JENKINSPROVIDER_PLACEHOLDER/$codestardemo_jenkinsprovider_name/ $f > $f.new && mv $f.new $f
    sed s/RDSTEST_DBNAME_PLACEHOLDER/$rdstest_dbname/ $f > $f.new && mv $f.new $f
    sed s/RDSTEST_DBHOST_PLACEHOLDER/$rdstest_dbhost/ $f > $f.new && mv $f.new $f
done

tar czf jobconfigs.tgz *
aws s3 cp jobconfigs.tgz s3://$codestardemo_s3bucket/$jobconfigs_tarball
popd > /dev/null
rm -rf $temp_dir

if ! aws s3 ls s3://$codestardemo_s3bucket/$jobconfigs_tarball; then
    echo "Fatal: Unable to upload Jenkins job configs to s3://$codestardemo_s3bucket/$jobconfigs_tarball" >&2
    exit 1
fi

aws cloudformation create-stack \
    --stack-name $codestardemo_jenkins_stackname \
    --template-body file://cloudformation/jenkins.json \
    --disable-rollback \
    --parameters ParameterKey=InstanceRole,ParameterValue=$instance_role \
        ParameterKey=S3Bucket,ParameterValue=$codestardemo_s3bucket \
        ParameterKey=JobConfigsTarball,ParameterValue=$jobconfigs_tarball \
        ParameterKey=KeyName,ParameterValue=$codestardemo_keyname \
        ParameterKey=IamInstanceProfile,ParameterValue=$instance_profile \
        ParameterKey=InstanceSecurityGroup,ParameterValue=$instance_sg \
        ParameterKey=SubnetId,ParameterValue=$subnet_id

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $codestardemo_jenkins_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $codestardemo_jenkins_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $codestardemo_jenkinks_stackname."
