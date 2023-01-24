# PLATFORM

NOTE: the working directory for this sectin is: `sa-ssp-aws/platform/`

In this section you will deploy two Auto Scale Groups (ASGs) of five EC2 servers each: 1 Vault ASG, 1 Consul ASG.

## Secrets Management - VAULT

### 1. Prepare for terraform deployment

With your AWS credentials exported, and the correct information added to your `$HOME/sa-ssp-aws/platform/vault-ent-aws/terraform.tfvars` from the steps above, you should now be able to run:

//TODO: ensure only the required information is added to the `sa-ssp-aws/inputs/terraform.tf-platform`

```sh
cd $HOME/sa-ssp-aws/platform/vault-ent-aws
terraform init
terraform plan
```

Unless you received errors from the above commands, you are now ready to deploy the Vault and Consul ASGs with:

```sh
terraform apply
```

Upon successful completion you should see:

```hcl
asg_name = "sa-vault"
cert_pem = <<EOT
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----

EOT
kms_key_arn = "arn:aws:kms:us-west-2:491229875064:key/bb2919c2-3dbc-40d8-8202-16c1b4c4582f"
launch_template_id = "lt-0ea7c56aae2ac149a"
vault_lb_arn = "arn:aws:elasticloadbalancing:us-west-2:491229875064:loadbalancer/net/sa-vault-lb/684ff521ebea47e4"
vault_lb_dns_name = "sa-vault-lb-684ff521ebea47e4.elb.us-west-2.amazonaws.com"
vault_lb_zone_id = "Z18D5FSROUN65G"
vault_sg_id = "sg-0cc56350d80b48eb0"
vault_target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:491229875064:targetgroup/sa-vault-tg/8f1285b19eb20e32"
```

You will need the `vault_lb_dns_name` value in the following steps.

Save the Vault CA locally:
```sh
terraform output -raw cert_pem > $HOME/sa-ssp-aws/inputs/vault-ca.pem
```

Add the VAULT_CACERT and VAULT_ADDR environment variables to you `~/.bashrc`:

```sh
echo "export VAULT_CACERT=$HOME/sa-ssp-aws/inputs/vault-ca.pem" >> ~/.bashrc
echo "export VAULT_ADDR=https://$(terraform output -raw vault_lb_dns_name):8200" >> ~/.bashrc
source ~/.bashrc
```

Verify vault communication with:
```sh
vault status
```

**NOTE:** Vault is currently: `Sealed: true`


### 2. Verify Vault Scale Group (OPTIONAL)

Using the AWS 'Secure Session Manager' (`aws ssm`) command, connect to a Vault instance and verify the Vault Cluster is running and healthy.

Using the AWS Auto Scaling Group (ASG) name in the above terraform output, get the `instance id` of an EC2 Scale Group member:

```sh
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names `terraform output -raw asg_name` --no-cli-pager --query "AutoScalingGroups[*].Instances[*].InstanceId"
```

Select an instance ID from the list and execute:

```sh
aws ssm start-session --target <instance_id>
```

To interact with Vault within a Vault cluster instance shell session you must export the following two variables:
```sh
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_CACERT="/opt/vault/tls/vault-ca.pem"
```

Verify Vault is running with:
```sh
vault status
```

Exit the shell session with the Vault cluster instance before continuing.

### 3. Initialize Vault Cluster

//TODO: Do I need to unseal every instance?

```sh
vault operator init
```

**NOTE** Copy the `Recovery Keys` and the `Initial Root Token` somewhere safe for future steps.

Export the Vault Token to provide appropriate permissions for following commands:

```sh
export VAULT_TOKEN=<initial_root_token>
```

Verify token permissions with the following:

```sh
vault operator raft list-peers
```

You should see something like:
```sh
Node                   Address              State       Voter
----                   -------              -----       -----
i-039ae7e6ddeb59b4d    10.0.102.121:8201    leader      true
i-0e238e7297f0d2b52    10.0.101.145:8201    follower    true
i-0d5546d3eeb23df85    10.0.103.55:8201     follower    true
i-0560234cb583fb773    10.0.103.35:8201     follower    true
i-0a403b210f7af110a    10.0.102.179:8201    follower    true
```

Unseal Vault:
```sh
vault operator unseal
```

You will be presented with the following prompt:

```sh
Unseal Key (will be hidden):
```

Enter the value of `Recovery Key 1:` retrieved from the `vault operator init` command above.

You should see an output as such:
```sh
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    5
Threshold                3
Version                  1.12.2+ent
Build Date               2022-11-23T21:33:30Z
Storage Type             raft
Cluster Name             vault-cluster-8a6b623b
Cluster ID               1e4d4bf9-7dce-44ff-126e-0526f3455157
HA Enabled               true
HA Cluster               https://10.0.101.40:8201
HA Mode                  active
Active Since             2023-01-11T18:07:07.686021267Z
Raft Committed Index     137
Raft Applied Index       137
Last WAL                 27
```

**NOTE:** Vault is now: `Sealed: false` and ready for use.

**NOTE:** Repeat this to unseal each Vault instance in the scale group //FIXME: but do I do this?


Vault does not enable dead server cleanup by default. Read more here: https://developer.hashicorp.com/vault/docs/concepts/integrated-storage/autopilot?_ga=2.183861359.832577255.1671558082-1844922285.1658445952#dead-server-cleanup

```sh
vault operator raft autopilot set-config \
    -cleanup-dead-servers=true \
    -dead-server-last-contact-threshold=10 \
    -min-quorum=3
```

### 3. Configure Vault for Consul Gossip Key

### n. Enable Vault Secrets Engine

```sh
vault secrets enable -path=consul kv-v2
```


Paste the contents of your locally saved Consul license located: `$HOME/sa-ssp-aws/inputs/consul.hclic`

Store Consul license in Vault:
```sh
vault kv put consul/secret/enterpriselicense key="$(cat $HOME/sa-ssp-aws/inputs/consul.hclic)"
```

You should see a response resembling:

```sh
============ Secret Path ============
consul/data/secret/enterpriselicense

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-11T20:03:29.449280648Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

You can read the license with:
```sh
vault kv get consul/secret/enterpriselicense
```

Store Consul Gossip Key in Vault - substituting the Consul Gossip Key generated earlier:

```sh
vault kv put consul/secret/gossip key="$(consul keygen)"
```

The respose should resemble:

```sh
====== Secret Path ======
consul/data/secret/gossip

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-11T20:06:47.450963339Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```


OPTIONAL: Verify with:

```sh
vault kv get consul/secret/gossip
```

### n. Configure Vault for Consul mTLS Cert Management

https://developer.hashicorp.com/consul/tutorials/vault-secure/vault-pki-consul-secure-tls


Setup PKI secrets engine:
```sh
vault secrets enable pki
```

//TODO: why is the example setting 10 year certs? WHY???

NOTE: "dc1.consul" is: `<consul_dc>.<consul_tld>`

```sh
vault secrets tune -max-lease-ttl=87600h pki
vault write -field=certificate pki/root/generate/internal \
    common_name="dc1.consul" \
    ttl=87600h | tee consul_ca.crt
```

Create a Vault role for the consul server:

```sh
vault write pki/roles/consul-server \
    allowed_domains="dc1.consul,consul-server,consul-server.consul,consul-server.consul.svc" \
    allow_subdomains=true \
    allow_bare_domains=true \
    allow_localhost=true \
    generate_lease=true \
    max_ttl="720h"
```

//TODO: this error comes back from `generate_lease`, why?:
```
WARNING! The following warnings were returned from Vault:

  * it is encouraged to disable generate_lease and rely on PKI's native
  capabilities when possible; this option can cause Vault-wide issues with
  large numbers of issued certificates
```


```sh
vault secrets enable -path connect-root pki
```


### n. Install the Vault Injector into k8s:

Disconnect from your AWS SSM session (don't run this in the Vault ASG instance):

```sh
cat > $HOME/sa-ssp-aws/inputs/vault-values.yaml << EOF
injector:
  enabled: true
  externalVaultAddr: "${VAULT_ADDR}"
EOF
```

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update
#helm install vault -f ./vault-values.yaml hashicorp/vault --version "0.20.0"
helm install vault -f $HOME/sa-ssp-aws/inputs/vault-values.yaml hashicorp/vault 
```
//TODO: pin this to avoid hashicorps breaking changes

**NOTE:** If you get the following error, you likely missed the `update-kubeconfig` command in the 'Infrastructure' section:
```sh
Error: Kubernetes cluster unreachable: Get "http://localhost:8080/version?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
```

To remedy, execute:
```sh
aws eks update-kubeconfig --region us-west-2 --name app_svcs-eks
```

### n. Enable k8s Auth

```sh
vault auth enable kubernetes
```

**NOTE** The Vault Injector Agent needs to be installed before these commands will work. If the Vault Injector Agent installed failed you will see:

```sh
Error from server (NotFound): serviceaccounts "vault" not found
```


```sh
export token_reviewer_jwt=$(kubectl get secret \
  $(kubectl get serviceaccount vault -o jsonpath='{.secrets[0].name}') \
  -o jsonpath='{ .data.token }' | base64 --decode)
```

```sh
export kubernetes_ca_cert=$(kubectl get secret \
  $(kubectl get serviceaccount vault -o jsonpath='{.secrets[0].name}') \
  -o jsonpath='{ .data.ca\.crt }' | base64 --decode)
```

```sh
export kubernetes_host_url=$(kubectl config view --raw --minify --flatten \
  -o jsonpath='{.clusters[].cluster.server}')
```


```sh
vault write auth/kubernetes/config \
  token_reviewer_jwt="${token_reviewer_jwt}" \
  kubernetes_host="${kubernetes_host_url}" \
  kubernetes_ca_cert="${kubernetes_ca_cert}"
```

```sh
vault read auth/kubernetes/config
```

This response should resemble:

```sh
Key                       Value
---                       -----
disable_iss_validation    true
disable_local_ca_jwt      false
issuer                    n/a
kubernetes_ca_cert        -----BEGIN CERTIFICATE-----
MIIC/jCCAeagAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
cm5ldGVzMB4XDTIzMDExMTE3MjU1OFoXDTMzMDEwODE3MjU1OFowFTETMBEGA1UE
AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALxN
4D97jnYvej6PPUBsnQE2L+z2x0picKztDLIeQazn+lxNekSRRGxrlPHDHsuIluBc
z2JKGtFqYKwIYx+/4yw6pHkCgR17v3sJHhUBkQTR/LO5tq4t5u3ukPc5qPflil+D
OZIXDl6tz4Fcy5DjjXuGPllPW+L4m3+tE9X06GVFrMAu9SiHtdCPFqYRtdH1qhbA
F35K6LsfUa7z7vyEBQVFYfIkY++XVY+Hsj3bsjLIY8ZkZcqArhThuMnIWPVgGiXR
OeQR8RR8xfBGqkXt9olALVumM3EJ79BiB3diXWSMUOu/tqdjBwlPtho1qwkgp7Fv
4iKerzOp9Q9wFbagT9UCAwEAAaNZMFcwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
/wQFMAMBAf8wHQYDVR0OBBYEFFq72DjUZQha7APNJ5ZZ85ezhzXhMBUGA1UdEQQO
MAyCCmt1YmVybmV0ZXMwDQYJKoZIhvcNAQELBQADggEBAIlkgJrJVlScDi32vOdc
JRFDlUComUtovtTNBGkI2uH0ygufpohj0FT0AsjNOswg+kRXbOZU+Wy/R8j3Pdts
+lcAR25K2ePACHwoZdtL8Q1a1byQ6tV5TMZOiUonj1uR5u6gwwZMngUXDqNBbJYY
E0wFQ3QcfPaE29YUwk1OJywslLX9qinANFlbi2JBqp6045qqvp/U8zO8utKGxbhf
p/VHvlFZoXIbuA5LiEm2om6z5KJ3pkMP4Ot5TOjuIHAdzXRLfUej3ARkrhlwRzBc
BoOJWeNR8ZpKuRz8AJ3eafdMoXgdhri0GCqzr5eLmbTDK0Ma9yiz9Zsaam72QH+U
NoY=
-----END CERTIFICATE-----
kubernetes_host           https://11A21DB9B12B13E5706CC9AD9CCD7187.gr7.us-west-2.eks.amazonaws.com
pem_keys                  []
```



**YOU ARE UP TO HERE: NEXT** Create Policies:
https://developer.hashicorp.com/consul/tutorials/vault-secure/kubernetes-vault-consul-secrets-management#generate-vault-policies




## Secure Communications - CONSUL


### 1. Create Consul Auto-Scale Group

```sh
cd $HOME/sa-ssp-aws/platform/consul-ent-aws
```

```sh
cp $HOME/sa-ssp-aws/inputs/terraform.tfvars-platform $HOME/sa-ssp-aws/platform/consul-ent-aws/terraform.tfvars
```

```sh
terraform init
terraform plan
terraform apply
```


### 2. Verify Consul Scale Group (OPTIONAL)

Using the AWS 'Secure Session Manager' (`aws ssm`) command, connect to a Consul instance and verify the Consul Cluster is running and healthy.

Using the AWS Auto Scaling Group (ASG) name in the above terraform output, get the `instance id` of an EC2 Scale Group member:

```sh
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names `terraform output -raw asg_name` --no-cli-pager --query "AutoScalingGroups[*].Instances[*].InstanceId"
```

Select an instance ID from the list and execute:

```sh
aws ssm start-session --target <instance_id>
```

To interact with Vault within a Vault cluster instance shell session you must export the following two variables:
```sh
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_CACERT="/opt/vault/tls/vault-ca.pem"
```

Verify Vault is running with:
```sh
vault status
```

Exit the shell session with the Vault cluster instance before continuing.