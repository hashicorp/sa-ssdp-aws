#!/bin/bash

if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] || [ -z $VAULT_ADDR ] || [ -z $VAULT_CACERT ]
then
   echo -e "Required env vars:\n\tAWS_ACCESS_KEY_ID\n\tAWS_SECRET_ACCESS_KEY\n\tVAULT_ADDR\n\tVAULT_CACERT"
else

  vault policy write consul policies/consul.hcl

#  AWS_CONSUL_IAM_ROLE_ARN=$(terraform output -state /root/terraform/iam/terraform.tfstate aws_consul_iam_role_arn)
  AWS_CONSUL_IAM_ROLE_ARN=$(terraform output -raw aws_consul_iam_role_arn)
  vault write auth/aws/role/consul auth_type=iam \
    bound_iam_principal_arn="${AWS_CONSUL_IAM_ROLE_ARN}" \
    policies=consul,admin ttl=30m

fi