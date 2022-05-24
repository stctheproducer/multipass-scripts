#!/bin/bash

cd ~/vault-policies

vault policy write admin ./admin-policy.hcl

vault write auth/token/roles/admin allowed_policies=admin token_period=2h orphan=true

admin_token=$(vault token create -display-name=admin-1 -role=admin | grep "token " | awk '{ print $2 }')

export VAULT_TOKEN=$admin_token

sed -i.bak "s/(VAULT_TOKEN=).*/\1$admin_token/" ~/.bashrc

# root_token=$(sudo cat ~/vault_init | grep "Initial Root Token" | cut -d ":" -f 2 | cut -d " " -f 2)

# vault token revoke $root_token

# renewable_token=$(vault token create -display-name=renewable-admin -ttl=12h -renewable=true -policy=admin | grep "token " | awk '{ print $2 }')

renewable_token=$(vault token create -display-name=renewable-admin -ttl=2h -renewable=true -policy=admin | grep "token " | awk '{ print $2 }')