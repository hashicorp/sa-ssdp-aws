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

  cat > $HOME/sa-ssdp-aws/inputs/consul-agent-values.yaml  << EOF
global:
  enabled: false
  name: consul-eks
  datacenter: us-west-2 #\${region}
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
      secretKey: key # bootstrapToken
    partitionToken: # https://www.consul.io/docs/k8s/deployment-configurations/vault/systems-integration
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
#  metrics:
#    enabled: true
  secretsBackend:
    vault:
      enabled: true
      consulClientRole: consul-eks-client
      consulCARole: consul-connect-ca
      manageSystemACLsRole: consul-eks-server-acl-init # ???
      adminPartitionsRole: consul-eks-partition-init # ???
#      agentAnnotations: |
#        "vault.hashicorp.com/namespace": "admin"
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
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: https://F105ECE9E0820C8BC60211EA9F0FE26C.gr7.us-west-2.eks.amazonaws.com # \${k8s_api_endpoint}

server:
  enabled: false

client:
  enabled: true
  join: 
  - "provider=aws tag_key=sa-consul tag_value=server"
#  nodeMeta:
#    terraform-module: "hcp-eks-client"

connectInject:
  transparentProxy:
    defaultEnabled: true
  enabled: true
  default: true
#  metrics:
#    defaultEnableMerging: true

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

dns:
  enabled: true
  enableRedirection: true

EOF

fi