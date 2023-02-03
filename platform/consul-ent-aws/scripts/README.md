# Helper Scripts

The following scripts automate the many commands required to configure Vault Ent to support Consul Ent.

* `auto-setup-vault.sh` - Configure Vault with the secrets required for secure Consul operation
* `auto-setup-consul.sh` - Confgure the Vault policy for Consul IAM authentication

## `auto-setup-vault.sh` - Requirements

Run this script BEFORE creating the consul cluster in `platform/consul-ent-aws`

```sh
AWS_ACCESS_KEY_ID=<aws_access_key_id>
AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
VAULT_ADDR=<vault_addr>
VAULT_CACERT=<vault_cacert>
AWS_VAULT_IAM_ROLE_ARN=<aws_vault_iam_role_arn>
```

## `auto-setup-consul.sh` - Requirements

Run this AFTER you have created your Consul cluster - it required the IAM Role ARN output from the cluster creation.

```sh
AWS_ACCESS_KEY_ID=<aws_access_key_id>
AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
VAULT_ADDR=<vault_addr>
VAULT_CACERT=<vault_cacert>
VAULT_TOKEN=<vault_token>
```

---

## Use

### Create AWS Infrastructure

```sh
export AWS_ACCESS_KEY_ID=<aws_access_key_id>
export AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
cd infrastructure/
terraform init
terraform plan
terraform apply
```

Create a `vault-ent-aws/terraform.tfvars` from the provided `terraform.tfvars.example` using the auto-generated values in `../inputs/terraform.tfvars-platform`.

### Deploy Vault Cluster

```sh
cd ../platform/vault-ent-aws
terraform init
terraform plan
terraform apply
```

### Configure Vault Cluster for Consul

```sh
cd ../consul-ent-aws
./scripts/auto-setup-vault.sh
```

Create a `consul-ent-aws/terraform.tfvars` from the provided `terraform.tfvars.example` using the values from `vault-ent-aws/terraform.tfvars`.

### Deploy the Consul Cluster:

```sh
cd ../consul-ent-aws
terraform init
terraform plan
terraform apply
```

### Configure Vault Policy for IAM

Export the Vault token provided in `aws_vault_keys.json`

```sh
export VAULT_TOKEN=$(cat $HOME/sa-ssdp-aws/inputs/aws_vault_keys.json | jq -r .root_token)
./scripts/auto-setup-consul.sh
```

## Verify Functioning Consul Cluster

```sh
export CONSUL_HTTP_TOKEN=`vault kv get -field=key consul/secret/initial_management`
```

Get IP Address on a Consul Server:

```sh
aws autoscaling describe-auto-scaling-instances --region us-west-2 --output text \
--query "AutoScalingInstances[?AutoScalingGroupName=='sa-consul'].InstanceId" \
| xargs -n1 aws ec2 describe-instances --instance-ids $ID --region us-west-2 \
--query "Reservations[].Instances[].PrivateIpAddress" --output text
```

Using any of the addresses in the list:

```sh
export CONSUL_HTTP_ADDR=<ip_address>
```

You should now be able to communicate with the Consul Cluster:

```sh
consul operator raft list-peers
```
