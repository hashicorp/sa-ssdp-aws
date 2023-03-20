#!/bin/bash

#Wait for box
sleep 20

#utils
sudo add-apt-repository ppa:rmescandon/yq -y
sudo apt update -y
sudo apt install -y jq yq unzip 

#hashicorp packages
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#install hashicorp packages
sudo apt update -y
sudo apt install consul-enterprise=${consul_version}+ent* vault-enterprise=${vault_version}+ent* terraform=1.3.* -y

#Install kubectl and helm
sudo apt-key adv --fetch-keys https://packages.cloud.google.com/apt/doc/apt-key.gpg
sudo apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-key adv --fetch-keys https://baltocdn.com/helm/signing.asc
sudo apt-add-repository "deb https://baltocdn.com/helm/stable/debian/ all main"
sudo apt update -y
sudo apt install kubectl=1.22.* helm=3.6.* -y

# Install awscli2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
rm -rf aws/
rm awscliv2.zip

# Install AWS Systems Manager Plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
rm session-manager-plugin.deb

export HOME=/home/ubuntu
cd $HOME
git config --global --add safe.directory $HOME/sa-ssdp-aws
git clone https://github.com/hashicorp/sa-ssdp-aws.git
cd sa-ssdp-aws

git checkout ${sa_release_version}
sudo chown -R ubuntu:ubuntu $HOME/sa-ssdp-aws

exit 0