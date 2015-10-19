#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"

ENVIRONMENT_FILE="$script_dir/../current_environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

echo "Creating $awsdevopsdemo_jenkins_stackname."

subnet_id="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_vpc_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue')"
instance_profile="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceProfile`].OutputValue')"
instance_role="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_iam_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceRole`].OutputValue')"
instance_sg="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_securitygroup_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceSecurityGroup`].OutputValue')"
rdstest_dbname="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_rds_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`RDSTestDBName`].OutputValue')"
rdstest_dbhost="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_rds_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`RDSTestDBHost`].OutputValue')"
rdstest_dbpasswd="$(aws cloudformation describe-stacks --stack-name $awsdevopsdemo_rds_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`RDSTestDBPasswd`].OutputValue')"

jenkins_configdir="$script_dir/../jenkins"
jenkins_tempdir=$(mktemp -d /tmp/$awsdevopsdemo_envname.XXXXX)
jenkins_configs_tarball="$awsdevopsdemo_jenkins_stackname/jenkins_configs-$(date +%s).tgz"

cp -r $jenkins_configdir/* $jenkins_tempdir/
pushd $jenkins_tempdir > /dev/null
for f in $(find . -name 'config.xml'); do
    sed s/JENKINSMASTERPASSWDHASH_PLACEHOLDER/$awsdevopsdemo_jenkinsmasterpasswdhash_entry/ $f > $f.new && mv $f.new $f
    sed s/JENKINSPROVIDER_PLACEHOLDER/$awsdevopsdemo_jenkinsprovider_name/ $f > $f.new && mv $f.new $f
    sed s/RDSTEST_DBNAME_PLACEHOLDER/$rdstest_dbname/ $f > $f.new && mv $f.new $f
    sed s/RDSTEST_DBHOST_PLACEHOLDER/$rdstest_dbhost/ $f > $f.new && mv $f.new $f
    sed s/RDSTEST_DBPASSWD_PLACEHOLDER/$rdstest_dbpasswd/ $f > $f.new && mv $f.new $f
done

tar czf jenkins_configs.tgz *
aws s3 cp jenkins_configs.tgz s3://$awsdevopsdemo_s3bucket/$jenkins_configs_tarball
popd > /dev/null

rm -rf $jenkins_tempdir

if ! aws s3 ls s3://$awsdevopsdemo_s3bucket/$jenkins_configs_tarball; then
    echo "Fatal: Unable to upload Jenkins job configs to s3://$awsdevopsdemo_s3bucket/$jenkins_configs_tarball" >&2
    exit 1
fi

aws cloudformation create-stack \
    --stack-name $awsdevopsdemo_jenkins_stackname \
    --template-body file://cloudformation/jenkins.json \
    --disable-rollback \
    --parameters ParameterKey=InstanceRole,ParameterValue=$instance_role \
        ParameterKey=S3Bucket,ParameterValue=$awsdevopsdemo_s3bucket \
        ParameterKey=JenkinsConfigsTarball,ParameterValue=$jenkins_configs_tarball \
        ParameterKey=KeyName,ParameterValue=$awsdevopsdemo_keyname \
        ParameterKey=IamInstanceProfile,ParameterValue=$instance_profile \
        ParameterKey=InstanceSecurityGroup,ParameterValue=$instance_sg \
        ParameterKey=SubnetId,ParameterValue=$subnet_id

stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $awsdevopsdemo_jenkins_stackname)"
if [ $? -ne 0 ]; then
    echo "Fatal: $(basename $0) stack $awsdevopsdemo_jenkins_stackname ($stack_status) failed to create properly" >&2
    exit 1
fi

echo "Created $awsdevopsdemo_jenkinks_stackname."
