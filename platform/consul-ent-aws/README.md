# Secure Consul Enterprise deployment on AWS

This terraform module creates an AWS Auto-Scale Group (ASG) for HashiCorp Consul Enterprise.

To support a secure, production-grade deployment, this module requires a Vault Cluster for:

* Consul TLS Certificate Management
* Consul Connect (sidecar) Certificate Management
* Consul Secrets Management for Consul Servers, Consul K8s agents, and Consul agents

This module was developed and test with (sa-ssdp-aws-tf-vault-ent)[https://github.com/hashicorp/sa-ssdp-aws-tf-vault-ent]

Configuration of the Vault Cluster requires various authentication providers, roles, and policies:

## Authentication Providers

* AWS - for server identity/auth via AWS IAM
* Kubernetes - for EKS services to authenticate with Vault and retrieve encrypted secrets

## Roles

## Secrets

Enable KV Secret path 'consul/' to store Consul secrets.

`vault secrets enable -path=consul kv-v2`

```sh
consul/secret/enterpriselicense
consul/secret/gossip
consul/secret/initial_management
consul/secret/partition_token
consul/secret/vault-ca
```

## PKI

Enable PKI and create Root Certificate.

```sh
vault secrets enable pki
```

  vault write -field=certificate pki/root/generate/internal \
      common_name="Company Inc" \
      key_type="ec" \
      key_bits="521" \
      ttl=87600h


## Policies

