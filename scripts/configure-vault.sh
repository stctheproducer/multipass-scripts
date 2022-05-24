#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if [[ $# -eq 2 ]]
  then
    consul_servers="$2"
elif [[ $# -eq 3 ]]
  then
    consul_servers="$2, $3, $4"
elif [[ $# -eq 4 ]]
  then
    consul_servers="$2, $3, $4, $5"
elif [[ $# -eq 5 ]]
  then
    consul_servers="$2, $3, $4, $5, $6"
else
  echo "Script has at least 2 arguments: $0 <datacenter name | consul servers>"
  exit 1
fi

datacenter=$1
instance_addr=$(hostname -I | awk '{print $1}')

# sudo mkdir --parents /opt/vault /var/log/vault

# echo "Creating vault system user…"

# sudo useradd --system --home /etc/vault.d --shell /bin/false vault

# sudo touch /opt/vault/vault-service-policy.hcl

# sudo chown --recursive vault:vault /opt/vault /var/log/vault
# echo "Moving certificates to vault data directory…"

# mkcert -cert-file vault-cert.pem -key-file vault-key.pem vault.local.test 127.0.0.1 localhost "$instance_addr"

# sudo mv vault-cert.pem vault-key.pem /opt/vault/tls

# sudo chmod 0640 /opt/tls/*

cat << CONSUL | sudo tee /etc/consul.d/consul.hcl
datacenter = "$datacenter"
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
ca_file = "/etc/consul/tls/agent-ca-cert.pem"
auto_encrypt {
  tls = true
}
retry_join = [<CONSUL_SERVER_ADDRESSES>]
CONSUL

cat << EOA | sudo tee /opt/vault/vault-service-policy.hcl
service "vault" { policy = "write" }
key_prefix "vault/" { policy = "write" }
agent_prefix "" { policy = "read" }
session_prefix "" { policy = "write" }
EOA
