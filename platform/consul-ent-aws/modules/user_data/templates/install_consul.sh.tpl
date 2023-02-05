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
  contents = "{{ with secret \"consul/data/secret/enterpriselicense\" }}{{ .Data.data.key}}{{ end }}"
  destination = "/etc/consul.d/consul.hclic"
  command = "sudo systemctl restart consul.service"
}

template {
  source = "/etc/vault-agent.d/consul-template.ctmpl"
  destination = "/etc/consul.d/consul.hcl"
  command = "sudo systemctl restart consul.service"
}

template {
  source = "/etc/vault-agent.d/consul-acl-template.ctmpl"
  destination = "/etc/consul.d/acl.hcl"
  command = "sudo systemctl restart consul.service"
}

template {
  source = "/etc/vault-agent.d/consul-ca-template.ctmpl"
  destination = "/opt/consul/tls/ca-cert.pem"
  command = "sudo systemctl restart consul.service"
}

template {
  source      = "/etc/vault-agent.d/consul-cert-template.ctmpl"
  destination = "/opt/consul/tls/server-cert.pem"
  command     = "sudo systemctl restart consul.service"
}

template {
  source      = "/etc/vault-agent.d/consul-key-template.ctmpl"
  destination = "/opt/consul/tls/server-key.pem"
  command     = "sudo systemctl restart consul.service"
}

EOF


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

cat > /etc/vault-agent.d/consul-template.ctmpl  << EOF
datacenter          = "${consul_dc}"
server              = true
bootstrap_expect    = ${bootstrap_expect}
data_dir            = "/opt/consul/data"
advertise_addr      = "$${local_ipv4}"
client_addr         = "0.0.0.0"
log_level           = "INFO"
license_path="/etc/consul.d/consul.hclic"

ui_config {
  enabled = true
}

# AWS cloud join
retry_join          = ["provider=aws tag_key=${name}-consul tag_value=server"]
# Max connections for the HTTP API
limits {
  http_max_conns_per_client = 128
}
performance {
    raft_multiplier = 1
}

## Service mesh CA configuration
connect {
  enabled = true
  ca_provider = "vault"
    ca_config {
        address = "${vault_addr}"
        token = "${consul_ca_token}"
        ca_file = "/opt/vault/tls/vault-ca.pem"
        root_pki_path = "connect_root"
        intermediate_pki_path = "connect_intermediate"
        leaf_cert_ttl = "72h"
        rotation_period = "2160h"
        intermediate_cert_ttl = "8760h"
        private_key_type = "rsa"
        private_key_bits = 2048
    }
}

EOF

cat > /etc/vault-agent.d/consul-acl-template.ctmpl << EOF
acl {
  enabled        = true
  default_policy = "deny"
  enable_token_persistence = true
  tokens {
    initial_management = "{{ with secret "consul/data/secret/initial_management" }}{{ .Data.data.key}}{{ end }}"
  }
}
encrypt="{{ with secret "consul/data/secret/gossip" }}{{ .Data.data.key}}{{ end }}"

EOF

cat > /etc/vault-agent.d/consul-ca-template.ctmpl << EOF
{{ with secret "pki/cert/ca" }}
{{ .Data.certificate }}
{{ end }}

EOF

cat > /etc/vault-agent.d/consul-cert-template.ctmpl << EOF
{{ with secret "pki/issue/consul" "common_name=consul-server-0.server.${consul_dc}.consul" "alt_names=consul-server-0.server.${consul_dc}.consul,server.${consul_dc}.consul,localhost" "ip_sans=127.0.0.1" "key_usage=DigitalSignature,KeyEncipherment" "ext_key_usage=ServerAuth,ClientAuth" }}
{{ .Data.certificate }}
{{ end }}

EOF

cat > /etc/vault-agent.d/consul-key-template.ctmpl << EOF
{{ with secret "pki/issue/consul" "common_name=consul-server-0.server.${consul_dc}.consul" "alt_names=consul-server-0.server.${consul_dc}.consul,server.${consul_dc}.consul,localhost" "ip_sans=127.0.0.1" "key_usage=DigitalSignature,KeyEncipherment" "ext_key_usage=ServerAuth,ClientAuth" }}
{{ .Data.private_key }}
{{ end }}
EOF

cat > /etc/consul.d/tls.hcl << EOF
tls {
  defaults {
    ca_file                 = "/opt/consul/tls/ca-cert.pem"
    cert_file               = "/opt/consul/tls/server-cert.pem"
    key_file                = "/opt/consul/tls/server-key.pem"
    verify_outgoing         = true
  }
  internal_rpc {
    verify_incoming = true
    verify_server_hostname = true
  }
}

auto_encrypt = {
  allow_tls = true
}

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
