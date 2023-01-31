#!/bin/bash

if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] || [ -z $VAULT_ADDR ] || [ -z $VAULT_CACERT ]
then
   echo -e "Required env vars:\n\tAWS_ACCESS_KEY_ID\n\tAWS_SECRET_ACCESS_KEY\n\tVAULT_ADDR\n\tVAULT_CACERT"
else

  HOME=/home/ubuntu
  
  terraform output -raw cert_pem > $HOME/sa-ssp-aws/inputs/vault-ca.pem
# VAULT_CACERT=$HOME/sa-ssp-aws/inputs/vault-ca.pem
# VAULT_ADDR=https://$(terraform output -raw vault_lb_dns_name):8200
  
  # Initialize
  VAULT_INIT=$(vault operator init -status)

  if [ $? = 2 ]
  then
    vault operator init -recovery-shares=1 -recovery-threshold=1 -format=json | jq . > ./aws_vault_keys.json
  else
    echo "Vault Already initialized. Looking for keys output: $(cat ./aws_vault_keys.json)"
  fi
  
  #Give it a moment to auto-uneal via AWS KMS
  sleep 20
  
  export VAULT_TOKEN=$(cat ./aws_vault_keys.json | jq -r .root_token)
  
  # Store Consul Secrets in Vault
  vault secrets enable -path=consul kv-v2
  vault kv put consul/secret/enterpriselicense key="$(cat $HOME/sa-ssp-aws/inputs/consul.hclic)"
  vault kv put consul/secret/gossip key="$(consul keygen)"
  
  # Enable PKI for Conusl Certs
  vault secrets enable pki
  vault secrets tune -max-lease-ttl=87600h pki
  vault write -field=certificate pki/root/generate/internal \
      common_name="dc1.consul" \
      ttl=87600h | tee consul_ca.crt
  
  vault write pki/roles/consul-server \
      allowed_domains="dc1.consul,consul-server,consul-server.consul,consul-server.consul.svc" \
      allow_subdomains=true \
      allow_bare_domains=true \
      allow_localhost=true \
      generate_lease=true \
      max_ttl="720h"
  
  vault secrets enable -path connect-root pki
  
  # Enable AWS Auth 
  vault auth enable aws

  AWS_VAULT_IAM_ROLE_ARN=$(terraform output -raw aws_vault_iam_role_arn)
  vault write auth/aws/role/vault \
    auth_type=iam \
    bound_iam_principal_arn=${AWS_VAULT_IAM_ROLE_ARN} \
    policies=vault,consul ttl=30m

  # Enable K8s Auth
  aws eks update-kubeconfig --region us-west-2 --name app_svcs-eks
  
  cat > $HOME/sa-ssp-aws/inputs/vault-values.yaml << EOF
injector:
  enabled: true
  externalVaultAddr: "${VAULT_ADDR}"
EOF
  
  helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update
  helm install vault -f $HOME/sa-ssp-aws/inputs/vault-values.yaml hashicorp/vault --version "0.23.0" 
  
  vault auth enable kubernetes
  token_reviewer_jwt=$(kubectl get secret \
    $(kubectl get serviceaccount vault -o jsonpath='{.secrets[0].name}') \
    -o jsonpath='{ .data.token }' | base64 --decode)
  kubernetes_ca_cert=$(kubectl get secret \
    $(kubectl get serviceaccount vault -o jsonpath='{.secrets[0].name}') \
    -o jsonpath='{ .data.ca\.crt }' | base64 --decode)
  kubernetes_host_url=$(kubectl config view --raw --minify --flatten \
    -o jsonpath='{.clusters[].cluster.server}')
  
  vault write auth/kubernetes/config \
    token_reviewer_jwt="${token_reviewer_jwt}" \
    kubernetes_host="${kubernetes_host_url}" \
    kubernetes_ca_cert="${kubernetes_ca_cert}"
  
  vault read auth/kubernetes/config

  echo "Using these:"
  echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
  echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
  echo "VAULT_ADDR=${VAULT_ADDR}"
  echo "VAULT_CACERT=${VAULT_CACERT}"
  echo "VAULT_TOKEN=${VAULT_TOKEN}"

fi