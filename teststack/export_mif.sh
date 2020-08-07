source env.txt

if [ "$1" == "" ]; then
    echo "Usage:   . $0 <stack-name>"
    echo "Example: . $0 mamifs01"
    echo "Where,"
    echo "  <stack-name> is name of your stack in XXXXTSNN format"
    exit 1
fi

BUCKET_NAME=manh-stack-$1

# create a bucket
echo "creating bucket $BUCKET_NAME"
aws s3api create-bucket --bucket $BUCKET_NAME > /dev/null

# Setup versioning
echo "Enabling versioning for $BUCKET_NAME"
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

cd ./deployment/aws/cloudformation/

zip -r scripts.zip scripts

aws s3api put-object --bucket $BUCKET_NAME --key scripts.zip --body scripts.zip > /dev/null

rm -rf scripts.zip

cd ../../../


echo "MIF Installer to $BUCKET_NAME"
aws s3api put-object --bucket $BUCKET_NAME --key MIFinstaller_2017.zip --body MIFinstaller_2017.zip > /dev/null


echo "MIF Cloud Formation script to $BUCKET_NAME"
aws s3 cp ./deployment s3://$BUCKET_NAME/deployment --recursive > /dev/null

# Creating MIF Stack
echo "Starting MIF stack creation on $AWS_DEFAULT_REGION Region !!!!!!!!!!!!!"
aws cloudformation create-stack --stack-name $1 --capabilities CAPABILITY_IAM --template-body file://deployment/aws/cloudformation/templates/master_mif.template --parameters "ParameterKey=AWSRegion,ParameterValue=$AWS_DEFAULT_REGION" "ParameterKey=ParentStackName,ParameterValue=$1" "ParameterKey=StackSize,ParameterValue=$STACK_SIZE" "ParameterKey=KeyName,ParameterValue=$AWS_KEY_PAIR_NAME" "ParameterKey=SpotPriceNeeded,ParameterValue=$SPOT_PRICE_NEEDED" "ParameterKey=SpotPriceMaxBid,ParameterValue=$SPOT_PRICE_MAX_BID" "ParameterKey=BaseDomain,ParameterValue=$BASE_DOMAIN" "ParameterKey=DBuserName,ParameterValue=$DB_USER_NAME" "ParameterKey=DBpassword,ParameterValue=$DB_PASSWORD" "ParameterKey=DBPort,ParameterValue=$DB_PORT" "ParameterKey=BackupRetentionPeriodValue,ParameterValue=$BACKUP_RETENTION_PERIOD_VALUE" "ParameterKey=StorageValue,ParameterValue=$STORAGE_VALUE" "ParameterKey=MultiAZValue,ParameterValue=$MULTI_AZ_VALUE" "ParameterKey=RDSAvailabilityZone,ParameterValue=$RDSAVAILABILITYZONE" "ParameterKey=CustomerCode,ParameterValue=$CUSTOMER_CODE" "ParameterKey=CostCenter,ParameterValue=$COST_CENTER" "ParameterKey=StackVersion,ParameterValue=$STACK_VERSION" "ParameterKey=SkipBlockDevice,ParameterValue=No" "ParameterKey=DeleteEBSVolumeOnInstanceTermination,ParameterValue=$DELETEEBSVOLUMEONINSTANCETERMINATION"
