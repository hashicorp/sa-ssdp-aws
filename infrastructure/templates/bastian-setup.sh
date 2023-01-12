#!/bin/bash

echo "started cloud init" >> /home/ubuntu/bastian.log

#wait for box
sleep 30

#utils
sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update -y
sudo apt install -y jq yq unzip 

#hashicorp packages
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#add envoy package
#curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
#echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
#echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list

#install packages
sudo apt update -y
sudo apt install consul-enterprise=${consul_version}+ent* vault-enterprise=${vault_version}+ent* -y
#sudo apt install consul-enterprise=1.12.8+ent* vault-enterprise=1.12.2+ent* getenvoy-envoy -y

#Install kubectl and helm
sudo apt-key adv --fetch-keys https://packages.cloud.google.com/apt/doc/apt-key.gpg
sudo apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-key adv --fetch-keys https://baltocdn.com/helm/signing.asc
sudo apt-add-repository "deb https://baltocdn.com/helm/stable/debian/ all main"
sudo apt update -y
sudo apt install kubectl=1.22.* helm=3.6.* terraform=1.3.* -y

# Install awscli2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
rm -rf aws/
rm awscliv2.zip

# So kubectl can talk to AWS EKS
#curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
#chmod +x aws-iam-authenticator
#sudo mv ./aws-iam-authenticator /usr/bin

#metadata
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
instance="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

#cd /home/ubuntu
#git clone https://github.com/hashicorp/sa-ssn-aws.git
#git config --global --add safe.directory /home/ubuntu/fra-ssn-aws
#cd fra-ssn-aws
##git checkout n8-add-hcp-vault #TODO: Change to FRA_VERSION
#
#FRA_ROOT=/home/ubuntu/fra-ssn-aws
#FRA_CONFIG_PATH=$FRA_ROOT/deployments/deployment1/configs
#KUBECONFIG=$FRA_CONFIG_PATH/kubeconfig
#
#
##dirs
#mkdir -p $FRA_CONFIG_PATH/consul-agent/
#
#
exit 0