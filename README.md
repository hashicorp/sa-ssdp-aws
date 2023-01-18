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

You will need to choose one of the following options:

1. Build with Terraform
2. Use existing Infrastructure

#### 1. Build with Terraform

The `sa-ssp-aws/infrastucture/` directory of this reposiory contains terraform infrastructure definitions to build out AWS resource for hosting the Secure Service Platform deployment. Once you've completed the [REQUIREMENTS](#REQUIREMENTS) section below you are ready to execute the `terraform apply` within the `infrastructure/` directory.

The terraform apply takes apprximately 13 minutes to deploy.


#### 2. Use existing Infrastructure

If you have an existing environment, or wish to build your own VPCs and EKS clusters, you may skip the terraform infrastrucure build. You will require certain inputs to deploy the platform services in `./platform/`. The commands to extract this information from AWS can be found below in XXXX.

*NOTE:*  Following best practices, our Vault Cluster will not be available externally, over the internall. Hene, you will need a Bastian host that can access the Vault and Consul ASGs and the EKS kubectl API, as done in the Terraform infrastructure (Option 1).

### Structure of this repo
```sh
.
├── README.md
├── docs
├── infrastructure
│   └── modules
│       ├── vpc
│       └── eks
├── inputs
├── platform
│   ├── consul-ent-aws
│   └── vault-ent-aws
└── services
    ├── k8s-Microservices
    └── EC2-DB
```

---

## REQUIREMENTS

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
export AWS_ACCESS_KEY_ID=<aws_access_key_id>
export AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
```

#### 3. Generate Enterprise Licences

You require Enterprise Licesnes for both Vault and Consul. Save them somewhere locally, e.g.:

```sh
ls -l1 ./sa-ssp-aws/inputs
README.md
consul.hclic
vault.hclic
```

#### 4. Create a Consul Gossip Key

Create a Consul Gossip Key using a locally install consul binary (see Requirements section above) with the command below. Save this for storage as a Vault Secret in later steps.

```sh
consul keygen
```

---
## INFRASTRUCTURE

You can use terraform to build infrastructure, or use your own infrastructure. Choose one of the two options in this guide before commencing the **PLATFORM** build: [./docs/INFRASTRUCTURE.md](./docs/INFRASTRUCTURE.md)

---
