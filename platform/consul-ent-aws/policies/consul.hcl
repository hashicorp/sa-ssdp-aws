path "consul/data/secret/gossip"
{
  capabilities = ["read"]
}
path "consul/data/secret/enterpriselicense"
{
  capabilities = ["read"]
}
path "consul/data/secret/initial_management"
{
  capabilities = ["read"]
}
path "consul/data/secret/partition_token"
{
  capabilities = ["read"]
}
path "pki/issue/consul"
{
  capabilities = ["read","update"]
}
path "pki/cert/ca"
{
  capabilities = ["read"]
}