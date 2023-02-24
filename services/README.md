# HashiCups Demo Application

Te Payments API and DB are installed on EC2 instances in the 'payments' VPC.

The FrontEnd and API services are installed on EKS.

Install the microservices on EKS:

```sh
kubectl apply -f $HOME/sa-ssdp-aws/services/hashicups-k8s/manifests/
```

Deploy the Payments DB Virtual Machine (EC2) instance:

Create a terraform.tfvars file from the terrafomr.tfvars.example. You will need to provide the following inputs:

```hcl
vpc_id=<payments_vpc_id>
private_subnets=<payments_vpc_private_subnets>
```

```sh
cd $HOME/sa-ssdp-aws/services/hashicups-ec2-payments/
cp terraform.tfvars.example terraform.tfvars
```

```sh
cd $HOME/sa-ssdp-aws/services/hashicups-ec2-payments/
terraform init
terraform plan
terraform apply
```
