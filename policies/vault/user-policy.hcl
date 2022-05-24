path "kv/data/users/<user>/*" {
  capabilities = ["create", "update", "read"]
}

path "kv/delete/users/<user>/*" {
  capabilities = ["delete", "update"]
}

path "kv/undelete/users/<user>/*" {
  capabilities = ["update"]
}

path "kv/destroy/users/<user>/*" {
  capabilities = ["update"]
}

path "kv/metadata/users/<user>/*" {
  capabilities = ["list", "read", "delete"]
}

path "kv/metadata/" {
  capabilities = ["list"]
}

path "kv/metadata/users/" {
  capabilities = ["list"]
}

path "kv/data/shared/*" {
  capabilities = ["read"]
}