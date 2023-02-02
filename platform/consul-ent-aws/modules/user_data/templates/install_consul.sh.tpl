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


# removing any default installation files from /etc/vault.d/
rm -rf /etc/vault.d/*

# removing any default installation files from /etc/consul.d/
rm -rf /etc/consul.d/*

# remove Vault Server SystemD unit
systemctl stop vault.service
systemctl disable vault.service
rm /etc/systemd/system/vault.service
rm /usr/lib/systemd/system/vault.service

# Create Vault agent config file
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
  command = "sudo systemctl restart consul.service"
}

template {
  contents = "{{ with secret \"consul/data/secret/enterpriselicense\" }}{{ .Data.data.key}}{{ end }}"
  destination = "/etc/consul.d/consul.hclic"
  command = "sudo systemctl restart consul.service"
}

EOF
chown -R vault:vault /etc/vault-agent.d

cat > /etc/systemd/system/vault-agent.service << EOF 
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target
Wants=consul.service
[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/bin/vault agent -config /etc/vault-agent.d/vault-agent.hcl
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

# create consul server dirs
mkdir -p /opt/consul/tls/
mkdir -p /opt/consul/data/
chown -R consul:consul /opt/consul

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
  enabled        = true
  default_policy = "deny"
  enable_token_persistence = true
#  tokens {
#    master = ""
#  }
}
encrypt="{{ with secret "consul/data/secret/gossip" }}{{ .Data.data.key}}{{ end }}"
license_path="/etc/consul.d/consul.hclic"
EOF

rm /lib/systemd/system/consul.service
cat > /lib/systemd/system/consul.service  << EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
Requires=vault-agent.service
After=vault-agent.service
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
#ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl reset-failed
systemctl enable vault-agent.service
systemctl start vault-agent.service
systemctl start consul.service
