#!/usr/bin/env bash

imds_token=$( curl -Ss -H "X-aws-ec2-metadata-token-ttl-seconds: 30" -XPUT 169.254.169.254/latest/api/token )
instance_id=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/instance-id )
local_ipv4=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-ipv4 )
local_hostname=$( curl -Ss -H "X-aws-ec2-metadata-token: $imds_token" 169.254.169.254/latest/meta-data/local-hostname )

# Add HashiCorp packages

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Add envoy packages
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list

apt-get update
apt-get install -y consul-enterprise=${consul_version}+ent-* vault-enterprise=${vault_version}+ent-* awscli getenvoy-envoy jq unzip 


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
            role = "consul-gw"
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
  contents    = "{{ with secret \"consul/data/secret/enterpriselicense\" }}{{ .Data.data.key}}{{ end }}"
  destination = "/etc/consul.d/consul.hclic"
  command     = "sudo systemctl restart consul.service"
}

template {
  contents    = "{{ with secret \"consul/data/secret/initial_management\" }}{{ .Data.data.key}}{{ end }}"
  destination = "/etc/consul.d/consul.token"
  command     = "sudo systemctl restart consul.service"
}

template {
  source      = "/etc/vault-agent.d/consul-template.ctmpl"
  destination = "/etc/consul.d/consul.hcl"
  command     = "sudo systemctl restart consul.service"
}

template {
  source      = "/etc/vault-agent.d/consul-acl-template.ctmpl"
  destination = "/etc/consul.d/acl.hcl"
  command     = "sudo systemctl restart consul.service"
}

template {
  source      = "/etc/vault-agent.d/consul-ca-template.ctmpl"
  destination = "/opt/consul/tls/ca-cert.pem"
  command     = "sudo systemctl restart consul.service"
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

#//TODO: if [ ${gateway_type} = "mesh"] then

cat > /etc/vault-agent.d/consul-template.ctmpl << EOF
datacenter          = "${consul_dc}"
data_dir            = "/opt/consul/data"
advertise_addr      = "$${local_ipv4}"
client_addr         = "0.0.0.0"
log_level           = "INFO"
license_path        = "/etc/consul.d/consul.hclic"
partition           = "${consul_partition}"
# AWS cloud join
retry_join          = ["provider=aws tag_key=${name}-consul tag_value=server"]

EOF

cat > /etc/vault-agent.d/consul-acl-template.ctmpl << EOF
acl {
  enabled        = true
  default_policy = "deny"
  enable_token_persistence = true
  tokens {
    agent = "{{ with secret "consul/data/secret/initial_management" }}{{ .Data.data.key}}{{ end }}"
  }
}
encrypt="{{ with secret "consul/data/secret/gossip" }}{{ .Data.data.key}}{{ end }}"

EOF

cat > /etc/vault-agent.d/consul-ca-template.ctmpl << EOF
{{ with secret "pki/cert/ca" }}
{{ .Data.certificate }}
{{ end }}

EOF

cat > /etc/consul.d/tls.hcl << EOF
tls {
  defaults {
    ca_file                 = "/opt/consul/tls/ca-cert.pem"
    verify_outgoing         = true
  }
  internal_rpc {
    verify_incoming = true
    verify_server_hostname = true
  }
}
ports {
  http = -1
  grpc = 8502
#  tls_grpc = 8503
}
auto_encrypt = {
  tls = true
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
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF

cat > /lib/systemd/system/envoy.service  << EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
Requires=consul.service
After=consul.service
#ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
#EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/bin/consul connect envoy -gateway=mesh -partition "${consul_partition}" -register -service "mesh-gateway" -address "$${local_ipv4}:8443" -token-file /etc/consul.d/consul.token -- -l debug
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
