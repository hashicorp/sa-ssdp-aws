#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] || [ -z $VAULT_ADDR ] || [ -z $VAULT_CACERT ] || [ -z $AWS_VAULT_IAM_ROLE_ARN ]
then
   echo "Required env vars:"
   echo -e "AWS_ACCESS_KEY_ID      = ${AWS_ACCESS_KEY_ID}"
   echo -e "AWS_SECRET_ACCESS_KEY  = ${AWS_SECRET_ACCESS_KEY}"
   echo -e "VAULT_ADDR             = ${VAULT_ADDR}"
   echo -e "VAULT_CACERT           = ${VAULT_CACERT}"
   echo -e "AWS_VAULT_IAM_ROLE_ARN = ${AWS_VAULT_IAM_ROLE_ARN}"

   echo -e "\nHints:"
   echo -e "terraform output -state \$HOME/sa-ssdp-aws/platform/vault-ent-aws/terraform.tfstate -raw cert_pem > \$HOME/sa-ssdp-aws/inputs/vault-ca.pem"
   echo -e "export VAULT_CACERT=\$HOME/sa-ssdp-aws/inputs/vault-ca.pem" 
   echo -e "export VAULT_ADDR=https://\$(terraform output -state \$HOME/sa-ssdp-aws/platform/vault-ent-aws/terraform.tfstate -raw vault_lb_dns_name):8200"
   echo -e "export AWS_VAULT_IAM_ROLE_ARN=\$(terraform output -state \$HOME/sa-ssdp-aws/platform/vault-ent-aws/terraform.tfstate -raw aws_vault_iam_role_arn)"

else

  HOME=/home/ubuntu

  # Verify Vault is not already initialized.
  VAULT_INIT=$(vault operator init -status)
  if [ $? = 2 ]   # exit 2 means not initialized
  then
    # Initialize Vault
    echo "Initializing Vault Cluster..."
    vault operator init -recovery-shares=1 -recovery-threshold=1 -format=json | jq . > $HOME/sa-ssdp-aws/inputs/aws_vault_keys.json
    echo "Vault keys/token saved to $HOME/sa-ssdp-aws/inputs/aws_vault_keys.json"
  else
    # Vault Already Initialized
    echo "Vault already initialized. Looking for keys output: $(cat $HOME/sa-ssdp-aws/inputs/aws_vault_keys.json)"
  fi
  
  #Give it a moment to auto-uneal via AWS KMS
  sleep 20
  
  export VAULT_TOKEN=$(cat $HOME/sa-ssdp-aws/inputs/aws_vault_keys.json | jq -r .root_token)
  
  # Store Consul Secrets in Vault
  echo "Enable KV Secret path 'consul/' and store consul secrets..."
  vault secrets enable -path=consul kv-v2
  vault kv put consul/secret/enterpriselicense key="$(cat $HOME/sa-ssdp-aws/inputs/consul.hclic)"
  vault kv put consul/secret/gossip key="$(consul keygen)"
  vault kv put consul/secret/initial_management key=$(cat /proc/sys/kernel/random/uuid)
  vault kv put consul/secret/partition_token key=$(cat /proc/sys/kernel/random/uuid)
  vault kv put consul/secret/vault-ca key="$(cat $HOME/sa-ssdp-aws/inputs/vault-ca.pem)"

  # Enable PKI for Conusl Certs
  echo "Enable PKI and create Root Certificate"
  vault secrets enable pki
  vault secrets tune -max-lease-ttl=87600h pki
  vault write -field=certificate pki/root/generate/internal \
      common_name="HashiCorp CA" \
      key_type="ec" \
      key_bits="521" \
      ttl=87600h
  
  vault write pki/roles/consul \
      allowed_domains="consul,internal" \
      allow_subdomains=true \
      allow_localhost=true \
      max_ttl="720h"
  
  vault secrets enable -path connect-root pki

  echo "Applying Vault policies for Consul Secrets and PKI"  
  vault policy write consul $HOME/sa-ssdp-aws/platform/consul-ent-aws/policies/consul.hcl
  vault policy write connect $HOME/sa-ssdp-aws/platform/consul-ent-aws/policies/connect.hcl

  echo "Generating Consul Connect Policy Token"
  export CONSUL_CA_TOKEN=$(vault token create -policy=connect -format=json | jq .auth.client_token)

  # Enable AWS Auth
  echo "Enable AWS Auth w/ IAM Role for Vault..."
  vault auth enable aws

  vault write auth/aws/role/vault \
    auth_type=iam \
    bound_iam_principal_arn=${AWS_VAULT_IAM_ROLE_ARN} \
    policies=vault,consul ttl=30m

  echo -e "\nConfiguration complete using these:"
  echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
  echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
  echo "VAULT_ADDR=${VAULT_ADDR}"
  echo "VAULT_CACERT=${VAULT_CACERT}"
  echo "VAULT_TOKEN=${VAULT_TOKEN}"
  echo "CONSUL_CA_TOKEN=${CONSUL_CA_TOKEN}"

fi
