#!/bin/bash

# Use appropriate AMI based on region
case $DEPLOY_REGION in
  us-east-1)
    AMI_ID="ami-088484ab34cd9622d"
    ;;
  us-east-2) 
    AMI_ID="ami-0bd8d1e6a386638bf"
    ;;
  us-west-2) 
    AMI_ID="ami-067f0b34ab041764b"
    ;;
  ca-central-1) 
    AMI_ID="ami-0b169be60da52e1da"
    ;;
  eu-north-1) 
    AMI_ID="ami-00a91b9e0a538b0c6"
    ;;
  eu-south-1) 
    AMI_ID="ami-06c78840eda1c6464"
    ;;
  eu-west-1) 
    AMI_ID="ami-0f0d0911d82fea2d7"
    ;;
  eu-west-2) 
    AMI_ID="ami-07c5733dbc5af0b56"
    ;;
  eu-west-3) 
    AMI_ID="ami-0a0881f78a66f4baa"
    ;;
  eu-central-1) 
    AMI_ID="ami-0d23a3144777b775b"
    ;;
  ap-northeast-1) 
    AMI_ID="ami-00d99b966acbc651d"
    ;;
  ap-northeast-2) 
    AMI_ID="ami-0b56bf3a0cb67e0dd"
    ;;
  ap-northeast-3) 
    AMI_ID="ami-0b7cc5652ef8a1b78"
    ;;
  ap-south-1) 
    AMI_ID="ami-072bf189b8257f1dc"
    ;;
  ap-southeast-1) 
    AMI_ID="ami-010eb4be18aaf6e84"
    ;;
  ap-southeast-2) 
    AMI_ID="ami-0609dbe8a16e2b6d2"
    ;;
  sa-east-1) 
    AMI_ID="ami-0cde511b6667f71bf"
    ;;
esac
log " AMI_ID=$AMI_ID"
# Get the first public subnet in the VPC created for OCP cluster
BACKUP_FILE_NAME=terraform-backup-${CLUSTER_NAME}.zip
NEW_VPC_ID=$(cat $GIT_REPO_HOME/aws/ocp-terraform/terraform.tfstate | jq '.resources[] | select((.type | contains("aws_subnet")) and (.name | contains("master1")))' | jq '.instances[0].attributes.vpc_id' | tr -d '"')
NEW_VPC_PUBLIC_SUBNET_ID=$(cat $GIT_REPO_HOME/aws/ocp-terraform/terraform.tfstate | jq '.resources[] | select((.type | contains("aws_subnet")) and (.name | contains("master1")))' | jq '.instances[0].attributes.id' | tr -d '"')
log " NEW_VPC_PUBLIC_SUBNET_ID=$NEW_VPC_PUBLIC_SUBNET_ID"
log " BACKUP_FILE_NAME=$BACKUP_FILE_NAME"
cd $GIT_REPO_HOME/aws/ocp-bastion-host
rm -rf terraform.tfvars
# Create tfvars file
cat <<EOT >> terraform.tfvars
region                          = "$DEPLOY_REGION"
ami                             = "$AMI_ID"
access_key_id                   = "$AWS_ACCESS_KEY_ID"
secret_access_key               = "$AWS_SECRET_ACCESS_KEY"
key_name                        = "$SSH_KEY_NAME"
vpc_id                          = "$NEW_VPC_ID"
subnet_id                       = "$NEW_VPC_PUBLIC_SUBNET_ID"
unique_str                      = "$RANDOM_STR"
iam_instance_profile            = "masocp-deploy-instance-profile-$RANDOM_STR"
user_data = <<EOF
#! /bin/bash
shutdown -P "+1"
EOF
EOT
sed -i "s/<REGION>/$DEPLOY_REGION/g" variables.tf
log "==== Bastion host creation started ===="
terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false -auto-approve
log "==== Bastion host creation completed ===="