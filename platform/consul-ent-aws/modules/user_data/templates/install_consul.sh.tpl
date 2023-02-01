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

echo "${vault_ca}" > /opt/vault/tls/vault-ca.pem

# //TODO: Remove for GA!
echo "export VAULT_TOKEN=${vault_token}" >> /home/ubuntu/.bashrc
echo "export VAULT_ADDR=${vault_addr}" >> /home/ubuntu/.bashrc
echo "export VAULT_CACERT=/opt/vault/tls/vault-ca.pem" >> /home/ubuntu/.bashrc


# removing any default installation files from /etc/vault.d/
rm -rf /etc/vault.d/*

# remove Vault Server SystemD unit
rm /etc/systemd/system/vault.service

## //TODO: create vault agent config file...
# Create Vault agent config file
#  cat > $HOME/sa-ssp-aws/inputs/vault-values.yaml << EOF
mkdir -p /etc/vault-agent.d/
cat > /etc/vault-agent.d/vault-agent.hcl << EOF

exit_after_auth = true
pid_file = "./pidfile"

auto_auth {
    method "aws" {
        mount_path = "auth/aws"
        config = {
            type = "iam"
            role = "consul"
        }
    }

    sink "file" {
        wrap_ttl = "5m"
        config = {
            path = "/home/ubuntu/vault-token-via-agent"
        }
    }
}

vault {
  address = "${vault_addr}"
  ca_cert = "/opt/vault/tls/vault-ca.pem"
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
chown -R vault:vault /etc/vault-agent.d

cat > /etc/systemd/system/vault-agent.service << EOF 
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target

[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/bin/vault agent -config /etc/vault-agent.d/vault-agent.hcl
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF


################
# Consul Setup #
################

# removing any default installation files from /opt/consul/tls/
rm -rf /opt/consul/tls/*

# /opt/consul/tls should be readable by all users of the system
chmod 0755 /opt/consul/tls

cat > /etc/consul.d/consul.hcl.ctmpl  << EOF
datacenter          = "${datacenter}"
server              = true
bootstrap_expect    = ${bootstrap_expect}
data_dir            = "/opt/consul/data"
advertise_addr      = "$${local_ipv4}"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
# AWS cloud join
retry_join          = ["provider=aws tag_key=${name}-consul tag_value=server"]
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

systemctl enable vault-agent.service
systemctl start vault-agent.service
systemctl start consul.service
