# sa-ssp-aws
Solution Architecture - Secure Service Platform - AWS

- [Overiew](#Overview)
  - [Infrastructure (Choose 1)](#Infrastructure (Choose 1))
    - [1. Build with Terraform](#1.-Build-with-Terraform)
    - [2. Use existing Infrastructure](#2.-Use-existing-Infrastructure)
  - [Structure of this repo](#Structure-of-this-repo)
- [PREPARATION](#PREPARATION)
  - [1. Clone this repo](#1.-Clone-this-repo)
  - [2. Export AWS credentions](#2.-Export-AWS-credentions)
- [INFRASTRUCTURE](#INFRASTRUCTURE)
  - [Build Insfrastructure using Terraform (OPTION 1)](#Build-Insfrastructure-using-Terraform (OPTION 1))
    - [1. Deploy the Insfrastructure](3.-Deploy-the-Insfrastructure)
    - [2. Review Output & Prepare Platform deployment](#4.-Review-Output-&-Prepare-Platform-deployment)
    - [3. Create kubeconfig file](#3.-Create-kubeconfig-file)
  - [Use Existing Insfrastructure (OPTION 2)](#Use-Existing-Insfrastructure (OPTION 2))
    - [1. Collect the required infrastructure values](#1.-Collect-the-required-infrastructure-values)
    - [2. Prepare the Platform Service deployment](#2.-Prepare-the-Platform-Service-deployment)
- [PLATFORM](#PLATFORM)
  - [1. Prepare for terraform deployment](#1.-Prepare-for-terraform-deployment)
  - [](#)
  - [5. Verify Vault Scale Group](#5.-Verify-Vault-Scale-Group)


## Overview

This solution is broken into three sections:
* Infrastructure
* Platform
* Services

### Infrastructure (Choose 1)

1. Build with Terraform
2. Use existing Infrastructure

#### 1. Build with Terraform

If you are evaluating this solution without existing AWS VPCs and EKS clusters then, using the terraform code found in the `sa-ssp-aws/infrastucture/` directory of this reposiory. Using the instrucure below in XXXX.

#### 2. Use existing Infrastructure

If you have an existing environment, or wish to build your own VPCs and EKS clusters, you may skip the terraform infrastrucure build. You will require certain inputs to deploy the platform services in `./platform/`. The commands to extract this information from AWS can be found below in XXXX.

*NOTE:*  Following best practices, our Vault Cluster will not be available externally, over the internall. Hene, you will need a Bastian host that can access the Vault and Consul ASGs and the EKS kubectl API, as done in the Terraform infrastructure (Option 1).

### Structure of this repo
```sh
.
├── README.md
├── infrastructure
│   └── modules
│       ├── vpc
│       └── eks
├── platform
│   ├── aws_consul
│   └── aws_vault
└── services
    ├── k8s-Microservices
    └── EC2-DB
```

---

### REQUIREMENTS

* `git`
* `aws cli` - v2
* `session-manager-plugin` - v1.2 https://formulae.brew.sh/cask/session-manager-plugin
* `consul` - v1.12 locally installed
* `terraform` - v1.3 locally installed

**NOTE:** The AWS `session-manager-plugin` is used to remote shell into the Vault and Consul AWS Auto Scale Group (ASG) instances. 

## PREPARATION

#### 1. Clone this repo

Clone this repo:
```sh
git clone https://github.com/hashicorp/sa-ssp-aws.git
```

#### 2. Export AWS credentions

Just like the AWS CLI tool, the Terraform Provider for AWS *requires* both the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. Export these values, e.g.:

```sh
export AWS_ACCESS_KEY_ID=AKIA3VS7LW7HGXGSKWGK
export AWS_SECRET_ACCESS_KEY=usuVsOn4LiX3DWw+k93oZhERaPz+rZ03PfvTaNU2
```

#### 3. Generate Enterprise Licences

You require Enterprise Licesnes for both Vault and Consul. Put them in the `sa-ssp-aws/inputs` directory:

```sh
ls -l1 ./sa-ssp-aws/inputs
README.md
consul.hclic
vault.hclic
```

#### 4. Create a Consul Gossip Key

This will be stored as a Vault Secret.

```sh
consul keygen
```

It will look something like this:
`mpO9YcSq+YnOqK2Prd0igm2kQObneGCjspOfi7JSH70=`


## INFRASTRUCTURE

NOTE: working directory: `sa-ssp-aws/infrastructure/`

### Build Insfrastructure using Terraform (OPTION 1)

1. Clone this repo
2. Provide AWS credentials
3. Create Infrastructure
4. Review output
5. Verify infrastrucutre deployment


You may inspect the default values in the `sa-ssp-aws/infrastructure/variables.tf` file, and overwrite these details in the `terraform.tfvars`.

#### 1. Deploy the Insfrastructure

```sh
terraform init
terraform plan
terraform apply
```

#### 2. Review Output & Prepare Platform deployment

//TODO: Check this before GA, and annonymize

```sh
app_eks_cluster = "app_svcs-eks"
vpc_app_microservices_id = "vpc-09d3a9fe742e5b7cc"
vpc_payments = "vpc-07811002745250cba"
vpc_platform_services_id = "vpc-0a87f14b17dc9b95f"
vpc_platform_services_public_subnets = [
  "subnet-0796fe75989b746d8",
  "subnet-0b9a6b0dc28543d6f",
  "subnet-08f5ea71124639af9",
]
your_ip_addr = "157.131.55.230"
```

Using the Terraform output information, create a new `sa-ssp-aws/platform/terraform.tfvars` file by copying the  `sa-ssp-aws/platform/terraform.tfvars.example` file.


**//URGENT**

//FIXME: I *think* we should switch to the Bastian host from here... Or should we work out how to run local commands and 'push' the output to the ASG? 

**//URGENT**

#### 3. Create kubeconfig file

To access your EKS cluster you will use the aws cli tool to retrieve your kubeconfig:

```sh
aws eks update-kubeconfig --region <region-code> --name <my-cluster>
```

Example:
```sh
aws eks update-kubeconfig --region us-west-2 --name app_svcs-eks
```

Verify communications with:
```sh
kubectl cluster-info
kubectl get svc
```

### Use Existing Insfrastructure (OPTION 2)

**NOTE:** Ensure you have a bastion host that can access the Vault Cluster ASG instances and the EKS Cluster Kubenetes API.
#### 1. Collect the required infrastructure values

**NOTE:** The platform services build using terraform creates 3 VPCs and 1 EKS cluster.
While you can create this architecture in one VPC, if you are using multiple VPCs, ensure that appropriate VPC Peering and Routes exists to reach the Consul+Vault clusters.

If you are building your own infrastructure you will need to collect information from that infrastructure to feed into the 'platform services' terraform deployment.

The example output in the above terraform step titled '4. Review Output' is an example of what is required – the Terraform deployment is configured to provide this information about the infrastucture it creates. To deploy the platform services in the next section you will need to retrieve this information from your existing infrastrcture using the following `aws cli` commands:


**vpc ids**

Collect the VPC Ids from the following output:

```sh
aws ec2 describe-vpcs
```

**eks cluster id**

Get the EKS cluster name from the following output:

```sh
aws eks list-clusters
```

```json
{
    "clusters": [
        "app_svcs-eks"
    ]
}
```

And use that cluster name to get the EKS Cluster Id:

```sh
aws eks describe-cluster --name app_svcs-eks
```

**public subnets**

Collect the VPC Public Subnet IDs for the VPC in which you will create the Vault and Consul clusters.

```sh
aws ec2 describe-subnets
```

If you have many you can filters, e.g.:
```sh
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0a87f14b17dc9b95f"
```

**kubeconfig**

To access your EKS cluster you will use the aws cli tool to retrieve your kubeconfig:

```sh
aws eks update-kubeconfig --region <region-code> --name <my-cluster>
```

Example:
```sh
aws eks update-kubeconfig --region us-west-2 --name app_svcs-eks
```

Verify communications with:
```sh
kubectl cluster-info
kubectl get svc
```


#### 2. Prepare the Platform Service deployment

Using the information collected above from the aws cli commands, create a new `sa-ssp-aws/platform/terraform.tfvars` file by copying the `sa-ssp-aws/platform/terraform.tfvars.example` file and entering the appropriate value.

---

## PLATFORM

NOTE: the working directory for this sectin is: `sa-ssp-aws/platform/`

In this section you will deploy two Auto Scale Groups (ASGs) of five EC2 servers each: 1 Vault ASG, 1 Consul ASG.

### Secrets Management - VAULT

### 1. Prepare for terraform deployment

With your AWS credentials exported, and the correct information added to your `sa-ssp-aws/platform/terraform.tfvars` from the steps above, you should now be able to run:

```sh
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
kms_key_arn = "arn:aws:kms:us-west-2:652626842611:key/10a8c141-d359-495b-92fc-546fa00ff109"
launch_template_id = "lt-0bb553c46288080c6"
vault_lb_arn = "arn:aws:elasticloadbalancing:us-west-2:652626842611:loadbalancer/app/sa-vault-lb/1e4797b210ca679f"
vault_lb_dns_name = "internal-sa-vault-lb-1711292900.us-west-2.elb.amazonaws.com"
vault_lb_zone_id = "Z1H1FL5HABSF5"
vault_sg_id = "sg-0528380228b1666ce"
vault_target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:652626842611:targetgroup/sa-vault-tg/fbfde0da72d05fcf"
```

You will need the `vault_lb_dns_name` value in the following steps.

### 2. Verify Vault Scale Group

Using the AWS 'Secure Session Manager' (`aws ssm`) command, connect to a Vault instance and verify the Vault Cluster is running and healthy.

Using the AWS Auto Scaling Group (ASG) name in the above terraform output, get the `instance id` of an EC2 Scale Group member:

```sh
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names `terraform output -raw asg_name` --no-cli-pager --query "AutoScalingGroups[*].Instances[*].InstanceId"
```

Select an instance ID from the list.

```sh
aws ssm start-session --target <instance_id>
```

Export the following two variables so that you can interact with Vault:
```sh
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_CACERT="/opt/vault/tls/vault-ca.pem"
```

Verify Vault is running with:
```sh
vault status
```

### 3. Initialize Vault Cluster

```sh
vault operator init
```

Note the Recovery Keys and `Initial Root Token`

```sh
export VAULT_TOKEN=<initial_root_token>
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


### 3. Configure Vault for Consul Gossip Key
//TODO: **YOU ARE HERE** Everything above works.

https://developer.hashicorp.com/consul/tutorials/vault-secure/vault-pki-consul-secure-tls

### n. Enable Vault Secrets Engine

```sh
vault secrets enable -path=consul kv-v2
```


Copy the local `../../inputs/consul.hclic` to the Vault ASG instance:

```sh
cd ~
mkdir tmp
vi consul.hclic
```

Paste the contents of your locally saved Consul license located: `../../inputs/consul.hclic`

Store Consul license in Vault:
```sh
vault kv put consul/secret/enterpriselicense key="$(cat ./consul.hclic)"
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


Store Consul Gossip Key in Vault - substituting the Consul Gossip Key generated earlier:

```sh
vault kv put consul/secret/gossip gossip="<consul_gossip_key>"
```

For example: `vault kv put consul/secret/gossip gossip="mpO9YcSq+YnOqK2Prd0igm2kQObneGCjspOfi7JSH70="`

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


### n. Enable k8s Auth

```sh
vault auth enable kubernetes
```

**NOTE:** on your local machine! 
//TODO: move all this (The platform section) to a bastian host in platsvcs vpc


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


**NEXT** Create Policies:
https://developer.hashicorp.com/consul/tutorials/vault-secure/kubernetes-vault-consul-secrets-management#generate-vault-policies






### n. Install the Vault Injector into k8s:

Disconnect from your AWS SSM session (don't run this in the Vault ASG instance):

```sh
export VAULT_PRIVATE_ADDR=`terraform output -raw vault_lb_dns_name`
cat > vault-values.yaml << EOF
injector:
  enabled: true
  externalVaultAddr: "https://${VAULT_PRIVATE_ADDR}:8200"
EOF
```

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update
#helm install vault -f ./vault-values.yaml hashicorp/vault --version "0.20.0"
helm install vault -f ./vault-values.yaml hashicorp/vault
```


### Secure Communications - CONSUL
