# INFRASTRUCTURE

Choose one of the two options below.

1. Build Insfrastructure using Terraform (OPTION 1)
2. Use Existing Insfrastructure (OPTION 2)


## Build Insfrastructure using Terraform (OPTION 1)

**NOTE:** working directory: `sa-ssp-aws/infrastructure/`

1. Clone this repo
2. Provide AWS credentials
3. Create Infrastructure
4. Review output
5. Verify infrastrucutre deployment


You may inspect the default values in the `sa-ssp-aws/infrastructure/variables.tf` file, and overwrite these details in the `terraform.tfvars`.

### 1. Deploy the Insfrastructure

```sh
terraform init
terraform plan
terraform apply
```

**NOTE:** The terraform apply takes apprximately 13 minutes to deploy.


### 2. Review Output & Prepare Platform deployment

//TODO: Check this before GA, and annonymize

```sh
bastian_platsvcs = "ssh -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ubuntu@ec2-54-189-161-81.us-west-2.compute.amazonaws.com"
bastian_platsvcs_copy_licenses = "scp -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ../inputs/* ubuntu@ec2-54-189-161-81.us-west-2.compute.amazonaws.com:/home/ubuntu/sa-ssp-aws/inputs/"
vpc_app_microservices_id = "vpc-0a7be785bdb291c45"
vpc_payments = "vpc-05012a4b83dbc80b0"
vpc_platform_services_id = "vpc-053b252716a672bc5"
vpc_platform_services_public_subnets = [
  "subnet-071c6ecca31b3a4f7",
  "subnet-0ae1cfda61683bf6c",
  "subnet-016b8e5cec0d7ddeb",
]
your_ip_addr = "157.131.55.230"
```

Using the Terraform output `bastian_platsvcs_copy_licenses` string, copy the vault and consul enterprise license to the bastian host, e.g.:

```sh
scp -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ../inputs/* ubuntu@ec2-54-189-161-81.us-west-2.compute.amazonaws.com:/home/ubuntu/sa-ssp-aws/inputs/
```


### 3. Connect to the Bastian Host

//TODO: Should this be an AWS System Manager session, or SSH? Or should we provide both?


Using the credentials provided in the terraform output, connect to the bastian host. Example:

```sh
ssh -o 'IdentitiesOnly yes' -i '../inputs/bastian-key.pem' ubuntu@ec2-35-91-0-182.us-west-2.compute.amazonaws.com
```

Export your AWS Credentials so that you can communicate with AWS resources:

```sh
export AWS_ACCESS_KEY_ID=<aws_access_key_id>
export AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
```

### 4. Create kubeconfig file

To access your EKS cluster you will use the aws cli tool to retrieve your kubeconfig:

```sh
aws eks update-kubeconfig --region us-west-2 --name app_svcs-eks
```

You should see:
```sh
Added new context arn:aws:eks:us-west-2:491229875064:cluster/app_svcs-eks to /home/ubuntu/.kube/config
```

Verify communications with:
```sh
kubectl cluster-info
kubectl get svc
```

You are now ready to deploy and configure the Secure Services Platform. Proceed to [./docs/PLATFORM.md](./docs/PLATFORM.md)

---

## Use Existing Insfrastructure (OPTION 2)

**NOTE:** Ensure you have a bastion host that can access the Vault Cluster ASG instances and the EKS Cluster Kubenetes API.
### 1. Collect the required infrastructure values

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

### 2. Connect to your bastian host

Using SSH, or the AWS Systems Manager (`aws ssm start-session --target`), connect to your bastian host and locally clone the git repository used above:

```sh
cd ~
git clone https://github.com/hashicorp/sa-ssp-aws.git
cd sa-ssp-aws
```

Verify you have the required binaries install (listed in the REQUIREMENTS section above).

Install the consul-enterprise and vault enterprise binaries:

```sh
#add the hashicorp package repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#install hashicorp packages
sudo apt update -y
sudo apt install consul-enterprise=1.12.8+ent* vault-enterprise=1.12.2+ent* terraform=1.3.* -y
```

### 3. Prepare the Platform Service deployment

Using the information collected in [1. Collect the required infrastructure values](#1.-Collect-the-required-infrastructure-values) above from the aws cli commands, create a new `sa-ssp-aws/platform/vault-ent-aws/terraform.tfvars` file and enter the appropriate value.

Apply the outputs collected above to the terraform.tfvars file in `platform/vault-ent-aws`, e.g.:

```
region = "us-west-2"

allowed_inbound_cidrs_lb = ["10.0.0.0/16"]
vault_license_filepath = "../../inputs/vault.hclic"

private_subnet_ids      = ["subnet-0378c1d7091510d6f","subnet-070ba21940761bae0","subnet-029bca70aabeeb041"]
vpc_id                  = "vpc-0eae9dd8a08b86029"
key_name                = "bastian-key"
```

### 4. Copy the Licesnes

Paste the contents of your vault licence into:

```sh
vi ../../inputs/vault.hclic
```

Repeat for Consul:

```sh
vi ../../inputs/consul.hclic
```

