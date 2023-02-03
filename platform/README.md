# Deploy Platform Services

In this section you will deploy platform services for Secrets Management and Service to Service Communications.

* Secure Service to Service Communications is delivered using Consul (multi-platform service mesh)
* Secrets Management, for both the Consul Mesh and deployed apps/services, is delivered using Vault

The Vault Cluster must be operational before the Consul Cluster can be created, so that Consul can be configured to use Vault for:

* Secrets Management - Gossip Key, ACL Bootstrap Token, RPC certificate
* Consul Connect CA - certificate minting for the service mesh proxies

## Create a Vault Cluster

Working directory: `<git_repo>/platform/vault-ent-aws`

## Create a Consul Cluster

Working directory: `<git_repo>/platform/consul-ent-aws`

### Requirements
