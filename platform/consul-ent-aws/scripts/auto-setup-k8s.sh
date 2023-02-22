#!/bin/bash

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

  # Enable K8s Auth
  echo "Fetching Kubeconfig from EKS..."
  aws eks update-kubeconfig --region us-west-2 --name app_svcs-eks

  # Fetch K8s API Endpoint
  echo "Fetching K8s API Endpoint"
  export K8S_API_ENDPOINT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}':443) && echo "K8S_API_ENDPOINT: ${K8S_API_ENDPOINT}"

  # Store Vault LB Cert in kube secret
  echo "Storing Vault LB CA in kube secret..."
  kubectl create secret generic vault-ca --from-file=key=$VAULT_CACERT

  # Install Vault Agent on EKS
  echo "Installing Vault Agent for EKS..."  
  cat > $HOME/sa-ssdp-aws/inputs/vault-agent-values.yaml << EOF
injector:
  enabled: true
  externalVaultAddr: "${VAULT_ADDR}"
EOF
  
  helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update
  helm install vault -f $HOME/sa-ssdp-aws/inputs/vault-agent-values.yaml hashicorp/vault --version "0.23.0" 
  
#  for i in `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name sa-consul | grep -i instanceid  | awk '{ print $2}' | cut -d',' -f1| sed -e 's/"//g'`;
#  do aws ec2 describe-instances --instance-ids $i | grep -i PrivateIpAddress | awk '{ print $2 }' | head -1 | cut -d"," -f1;
#  done;

#  for i in `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name sa-consul | grep -i instanceid  | awk '{ print $2}' | cut -d',' -f1| sed -e 's/"//g'`;
#  do aws ec2 describe-instances --instance-ids $i | grep -i PrivateDnsName | awk '{ print $2 }' | head -1 | cut -d"," -f1;
#  done;


  # Enable vault auth for Kubernetes
  echo "Enabling Vault Auth for K8s"
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

  export K8S_CONSUL_GLOBAL_NAME="consul-eks"
  echo "Using K8S_CONSUL_GLOBAL_NAME: ${K8S_CONSUL_GLOBAL_NAME}"

  echo "Creating Vault Roles for K8s Service Accounts..."

  vault write auth/kubernetes/role/${K8S_CONSUL_GLOBAL_NAME}-partition-init \
      bound_service_account_names=${K8S_CONSUL_GLOBAL_NAME}-partition-init \
      bound_service_account_namespaces=default \
      policies=consul,connect \
      ttl=1h

  vault write auth/kubernetes/role/consul-connect-ca \
    bound_service_account_names=* \
    bound_service_account_namespaces=default \
    policies=consul,connect \
    ttl=1h
  
  vault write auth/kubernetes/role/${K8S_CONSUL_GLOBAL_NAME}-server-acl-init \
    bound_service_account_names=${K8S_CONSUL_GLOBAL_NAME}-server-acl-init \
    bound_service_account_namespaces=default \
    policies=consul,connect \
    ttl=1h

  vault write auth/kubernetes/role/${K8S_CONSUL_GLOBAL_NAME}-client \
      bound_service_account_names=${K8S_CONSUL_GLOBAL_NAME}-client \
      bound_service_account_namespaces=default \
      policies=consul,connect

  vault write auth/kubernetes/role/${K8S_CONSUL_GLOBAL_NAME}-server \
      bound_service_account_names=${K8S_CONSUL_GLOBAL_NAME}-server \
      bound_service_account_namespaces=default \
      policies=consul,connect

  cat > $HOME/sa-ssdp-aws/inputs/consul-agent-values.yaml  << EOF
global:
  enabled: false
  name: ${K8S_CONSUL_GLOBAL_NAME}
  datacenter: us-west-2
  image: "hashicorp/consul-enterprise:1.12.8-ent"
  imageEnvoy: "envoyproxy/envoy:v1.22.5"
  enableConsulNamespaces: true
  adminPartitions:
    enabled: true
    name: "us-west-2-eks"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: consul/data/secret/initial_management 
      secretKey: key
    partitionToken:
      secretName: consul/data/secret/partition_token
      secretKey: key
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: pki/cert/ca
      secretKey: certificate
  gossipEncryption:
    secretName: consul/data/secret/gossip 
    secretKey: key 
  secretsBackend:
    vault:
      enabled: true
      ca:
        secretName: vault-ca
        secretKey: key
      consulServerRole: ${K8S_CONSUL_GLOBAL_NAME}-server
      consulClientRole: ${K8S_CONSUL_GLOBAL_NAME}-client
      consulCARole: consul-connect-ca
      manageSystemACLsRole: ${K8S_CONSUL_GLOBAL_NAME}-server-acl-init
      adminPartitionsRole: ${K8S_CONSUL_GLOBAL_NAME}-partition-init
      connectCA:
       address: ${VAULT_ADDR}
       rootPKIPath: /connect-root
       intermediatePKIPath: /connect-intermediate
       additionalConfig: |
        {
          "connect": [{
            "ca_config": [{
              "leaf_cert_ttl": "72h",
              "intermediate_cert_ttl": "8760h",
              "rotation_period": "2160h",
              "namespace": "admin"
            }]
          }]
        }

externalServers:
  enabled: true
  hosts:
  - "provider=aws tag_key=sa-consul tag_value=server"
  useSystemRoots: false
  k8sAuthMethodHost: ${K8S_API_ENDPOINT}

server:
  enabled: false

client:
  enabled: true
  join: 
  - "provider=aws tag_key=sa-consul tag_value=server"

connectInject:
  transparentProxy:
    defaultEnabled: true
  enabled: true
  default: true

controller:
  enabled: true

ingressGateways:
  enabled: true
  gateways:
    - name: ingress-gateway
      service:
        type: LoadBalancer
        ports:
        - port: 80

meshGateway:
  enabled: true
  replicas: 1

dns:
  enabled: true
  enableRedirection: true

EOF

# helm install
helm install consul hashicorp/consul --values $HOME/sa-ssdp-aws/inputs/consul-agent-values.yaml --version=0.49.4 --debug --timeout 2m

fi