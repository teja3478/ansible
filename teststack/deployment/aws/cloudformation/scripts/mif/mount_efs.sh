#!/bin/sh

exec > /tmp/mount.log 2>&1
set -x

source /etc/manh/aws_environment.sh

EFS_STACK_ID=`aws cloudformation describe-stack-resources --region ${AWS_REGION} --stack-name ${PARENT_STACK} --logical-resource-id $1 --query "StackResources[*].PhysicalResourceId" --output text`
echo "EFS_STACK_ID: ${EFS_STACK_ID}"
if [ "$EFS_STACK_ID" == "" ]; then
    echo "ERROR: Failed obtaining EFS_STACK_ID"
    exit 1
fi

EFS_FILE_SYSTEM_ID=`aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${EFS_STACK_ID} --query "Stacks[*].Outputs" --output text | grep FileSystemID | cut -f4`
EFS_MOUNT_POINT=`aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${EFS_STACK_ID} --query "Stacks[*].Outputs" --output text | grep MountPoint | cut -f4`
echo "EFS_FILE_SYSTEM_ID: ${EFS_FILE_SYSTEM_ID}"
echo "EFS_MOUNT_POINT: ${EFS_MOUNT_POINT}"

if [ -d "$EFS_MOUNT_POINT" ]; then
    echo "Directory ${EFS_MOUNT_POINT} already exist. Skipping mounting EFS..."
    exit 0
fi
    echo "Create dir ${EFS_MOUNT_POINT}"
    mkdir -p ${EFS_MOUNT_POINT}
    #MNT_CMD=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"."${EFS_FILE_SYSTEM_ID}".efs."${AWS_REGION}".amazonaws.com:/ "${EFS_MOUNT_POINT}
    MNT_CMD=${EFS_FILE_SYSTEM_ID}".efs."${AWS_REGION}".amazonaws.com"
    for z in {0..120}; do host $MNT_CMD && break; sleep 1; done
    nslookup $MNT_CMD >> /tmp/t
    echo "Mount EFS command: mount -t nfs4 ${MNT_CMD}:/ ${EFS_MOUNT_POINT}"
      mount -t nfs4 ${MNT_CMD}:/ ${EFS_MOUNT_POINT}
echo "[$(date)] mount_efs.sh complete" >> /tmp/mount.log
 chown -R $2:$2 ${EFS_MOUNT_POINT}

