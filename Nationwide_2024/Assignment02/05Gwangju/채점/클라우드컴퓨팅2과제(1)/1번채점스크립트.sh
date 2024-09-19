echo -e "========1-1-A========"
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=gwangju-VPC2 --query 'Vpcs[*].VpcId' --output text)" --query 'NetworkAcls[*].Entries' --output json

echo -e "\n========1-1-B========"
VPC_NAME_TAGS=("gwangju-VPC1" "gwangju-VPC2" "gwangju-EgressVPC")
for VPC_NAME_TAG in ${VPC_NAME_TAGS[@]};
do
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${VPC_NAME_TAG}" --query "Vpcs[*].VpcId" --output text)
  SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text)
  for SUBNET_ID in $SUBNET_IDS;
  do
      NACL_ID=$(aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values=${SUBNET_ID}" --query "NetworkAcls[*].Associations[?SubnetId=='${SUBNET_ID}'].NetworkAclId" --output text)
      IS_DEFAULT=$(aws ec2 describe-network-acls --network-acl-ids ${NACL_ID} --query "NetworkAcls[*].IsDefault" --output text)
      echo $IS_DEFAULT
  done
done

echo -e "\n========1-2-A========"
INSTANCE_NAME_TAG="gwangju-VPC2-Instance"
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE_NAME_TAG}" --query "Reservations[*].Instances[*].InstanceId" --output text)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
ping $PRIVATE_IP -c 4 | grep -E 'packets transmitted|received' | awk '{print $1, $4}'
VPC_ID=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].VpcId" --output text)
VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --query "Vpcs[*].Tags[?Key=='Name'].Value" --output text)
echo "$VPC_NAME"

echo -e "\n========1-2-B========"
ping 1.1.1.1 -c 4 | grep -E 'packets transmitted|received' |awk '{print $1, $4}'

echo -e "\n========1-3-A========"
INSTANCE_NAME_TAG="gwangju-VPC1-Instance"
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE_NAME_TAG}" --query "Reservations[*].Instances[*].InstanceId" --output text)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
ping $PRIVATE_IP -c 4 | grep -E 'packets transmitted|received' | awk '{print $1, $4}'
VPC_ID=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].VpcId" --output text)
VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --query "Vpcs[*].Tags[?Key=='Name'].Value" --output text)
echo "$VPC_NAME"

echo -e "\n========1-3-B========"
INSTANCE_NAME_TAG="gwangju-VPC2-Instance"
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE_NAME_TAG}" --query "Reservations[*].Instances[*].InstanceId" --output text)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
ping $PRIVATE_IP -c 4 | grep -E 'packets transmitted|received' | awk '{print $1, $4}'
VPC_ID=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query "Reservations[*].Instances[*].VpcId" --output text)
VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --query "Vpcs[*].Tags[?Key=='Name'].Value" --output text)
echo "$VPC_NAME"

echo -e "\n========1-3-C========"
ping 1.1.1.1 -c 4 | grep -E 'packets transmitted|received' |awk '{print $1, $4}'