#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] || [ -z $VAULT_ADDR ] || [ -z $VAULT_CACERT ] || [ -z $VAULT_TOKEN ]
then
   echo "Required env vars:"
   echo -e "\tAWS_ACCESS_KEY_ID     = ${AWS_ACCESS_KEY_ID}"
   echo -e "\tAWS_SECRET_ACCESS_KEY = ${AWS_SECRET_ACCESS_KEY}"
   echo -e "\tVAULT_ADDR            = ${VAULT_ADDR}"
   echo -e "\tVAULT_CACERT          = ${VAULT_CACERT}"
   echo -e "\tVAULT_TOKEN           = ${VAULT_TOKEN}"

   echo -e "\nHints:"
   echo -e "terraform output -state \$HOME/sa-ssdp-aws/platform/vault-ent-aws/terraform.tfstate -raw cert_pem > \$HOME/sa-ssdp-aws/inputs/vault-ca.pem"
   echo -e "export VAULT_CACERT=\$HOME/sa-ssdp-aws/inputs/vault-ca.pem" 
   echo -e "export VAULT_ADDR=https://\$(terraform output -state \$HOME/sa-ssdp-aws/platform/vault-ent-aws/terraform.tfstate -raw vault_lb_dns_name):8200"
   echo -e "export VAULT_TOKEN=\$(cat \$HOME/sa-ssdp-aws/inputs/aws_vault_keys.json | jq -r .root_token)" 

else

  AWS_CONSUL_IAM_ROLE_ARN=$(terraform output -state $HOME/sa-ssdp-aws/platform/consul-ent-aws/terraform.tfstate -raw aws_consul_iam_role_arn)
  if [ -z $AWS_CONSUL_IAM_ROLE_ARN ]
  then
    echo -e "Unable to retrieve Consul IAM Role ARN:\n\tAWS_CONSUL_IAM_ROLE_ARN = $AWS_CONSUL_IAM_ROLE_ARN"
  else
    vault write auth/aws/role/consul auth_type=iam \
      bound_iam_principal_arn="${AWS_CONSUL_IAM_ROLE_ARN}" \
      policies=consul,connect,admin ttl=30m

  fi

  echo -e "\nConfiguration complete using these:"
  echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
  echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
  echo "VAULT_ADDR=${VAULT_ADDR}"
  echo "VAULT_CACERT=${VAULT_CACERT}"
  echo "VAULT_TOKEN=${VAULT_TOKEN}"

fi
