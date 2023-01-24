#!/usr/bin/env bash

imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 30" -XPUT 169.254.169.254/latest/api/token )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )

# install package

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y consul-enterprise=${consul_version}+ent-* vault-enterprise=${vault_version}+ent-* awscli jq unzip

echo "Configuring system time"
timedatectl set-timezone UTC

################
# Vault Setup #
################

# removing any default installation files from /opt/vault/tls/
rm -rf /opt/vault/tls/*

# /opt/vault/tls should be readable by all users of the system
chmod 0755 /opt/vault/tls

# vault-key.pem should be readable by the vault group only
#touch /opt/vault/tls/vault-key.pem
#touch /opt/vault/tls/vault-ca.pem
#chown root:vault /opt/vault/tls/vault-key.pem
#chmod 0640 /opt/vault/tls/vault-key.pem


echo ${vault_ca} > /opt/vault/tls/vault-ca.pem

echo "export VAULT_TOKEN=${vault_token}" >> /home/ubuntu/.bashrc
echo "export VAULT_ADDR=${vault_addr}" >> /home/ubuntu/.bashrc
echo "export VAULT_CACERT=/opt/vault/tls/vault-ca.pem" >> /home/ubuntu/.bashrc


## //TODO: create vault agent config file...


################
# Consul Setup #
################

# removing any default installation files from /opt/consul/tls/
rm -rf /opt/consul/tls/*

# /opt/consul/tls should be readable by all users of the system
chmod 0755 /opt/consul/tls

cat << EOF > /etc/consul.d/consul.hcl.ctmpl
datacenter          = "${datacenter}"
server              = true
bootstrap_expect    = ${bootstrap_expect}
data_dir            = "/opt/consul/data"
advertise_addr      = "$${local_ipv4}"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
# AWS cloud join
retry_join          = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
# Max connections for the HTTP API
limits {
  http_max_conns_per_client = 128
}
performance {
    raft_multiplier = 1
}
acl {
  enabled        = false #TODO: true
  default_policy = "allow"
  enable_token_persistence = true
#  tokens {
#    master = ""
#  }
}
encrypt="{{ with secret "consul/data/secret/gossip" }}{{ .Data.data.key}}{{ end }}"
license_path="/etc/consul.d/consul.hclic"
EOF

###########################
# Install consul-template #
###########################

wget https://releases.hashicorp.com/consul-template/0.30.0/consul-template_0.30.0_linux_amd64.zip
unzip consul-template_0.30.0_linux_amd64.zip
mv consul-template /usr/bin/
rm consul-template_0.30.0_linux_amd64.zip
mkdir /etc/consul-template.d/

cat << EOF > /etc/consul-template.d/consul-template.hcl
log_level = "warn"

vault {
  # This is the address of the Vault leader. The protocol (http(s)) portion
  # of the address is required.
  address = "${vault_addr}"
  token = "${vault_token}"
  renew_token = false

  ssl {
    # This enables SSL. Specifying any option for SSL will also enable it.
    enabled = true
    ca_cert = "/opt/vault/tls/vault-ca.pem"
  }
}

template {
  source = "/etc/consul.d/consul.hcl.ctmpl"
  destination = "/etc/consul.d/consul.hcl"
}

template {
  contents = "{{ with secret \"consul/data/secret/enterpriselicense\" }}{{ .Data.data.key}}{{ end }}"
  destination = "/etc/consul.d/consul.hclic"
}
EOF

cat << EOF > /etc/systemd/system/consul-template.service
[Unit]
Description=consul-template
Requires=network-online.target
#After=network-online.target consul.service vault.service

[Service]
EnvironmentFile=-/etc/sysconfig/consul-template
Restart=on-failure
ExecStart=/usr/bin/consul-template -config=/etc/consul-template.d
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable consul-template.service
systemctl start consul-template.service
systemctl start consul.service