#!/bin/bash
if [[ $# -eq 0 ]]
  then
    echo "No arguments supplied"
    exit 1
elif ! [[ $# -ge 1 ]]
  then
    echo "Script has at least 2 arguments: $0 <datacenter name | consul servers>"
    exit 1
fi

server_addr=$1
instance_addr=$(hostname -I | awk '{print $1}')

if ! [[ -d /tmp/hashicorp ]]
  then
    mkdir -p /tmp/hashicorp
fi

cd /tmp/hashicorp

export VAULT_VERSION="1.9.2"

export VAULT_URL="https://releases.hashicorp.com/vault"

echo "Downloading Vault…"

curl --remote-name \
  ${VAULT_URL}/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

curl --silent --remote-name \
  ${VAULT_URL}/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS

curl --silent --remote-name \
  ${VAULT_URL}/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig

echo "Unzipping package…"

unzip vault_${VAULT_VERSION}_linux_amd64.zip

sudo chown root:root vault

sudo mv vault /usr/bin/

vault -autocomplete-install

complete -C /usr/bin/vault vault

sudo mkdir --parents /opt/vault /var/log/vault

echo "Creating vault system user…"

sudo useradd --system --home /etc/vault.d --shell /bin/false vault

sudo touch /opt/vault/vault-service-policy.hcl

sudo chown --recursive vault:vault /opt/vault /var/log/vault

echo "Moving certificates to vault data directory…"

sudo mv /home/$USER/tls /opt/vault/

sudo chown root:root /opt/vault/tls

sudo chown root:root /opt/vault/tls/vault-cert.pem /opt/vault/tls/vault-ca.pem

sudo chown root:vault /opt/vault/tls/vault-key.pem

sudo chmod 0644 /opt/vault/tls/vault-cert.pem /opt/vault/tls/vault-ca.pem

sudo chmod 0640 /opt/vault/tls/vault-key.pem

sudo cp /opt/vault/tls/vault-ca.pem /usr/local/share/ca-certificates/vault-ca.crt

 sudo update-ca-certificates

echo "Adding configuration files…"

cat << EOA | sudo tee /opt/vault/vault-service-policy.hcl
service "vault" { policy = "write" }
key_prefix "vault/" { policy = "write" }
agent_prefix "" { policy = "read" }
session_prefix "" { policy = "write" }
EOA

# consul acl policy create -name vault-service -rules /opt/vault/vault-service-policy.hcl

# acl_token=$(consul acl token create \
#     -description "Vault Service Token" \
#     -policy-name vault-service)

sudo mkdir --parents /etc/vault.d

sudo touch /etc/vault.d/vault.hcl

cat << EOB | sudo tee /etc/vault.d/vault.hcl
cluster_addr = "https://$instance_addr:8201"
api_addr     = "https://$instance_addr:8200"
ui           = true

data_dir = "/opt/vault"

log_file = "/var/log/vault/vault.log"

listener "tcp" {
  address     = "vault.local.test:8200"
  // tls_disable = 1
  tls_cert_file      = "/opt/vault/tls/vault-cert.pem"
  tls_key_file       = "/opt/vault/tls/vault-key.pem"
  tls_client_ca_file = "/opt/vault/tls/vault-ca.pem"
}

storage "consul" {
  address = "http://localhost:8500"
  path    = "vault/"
  // token   = "$acl_token"
}
EOB

sudo touch /etc/systemd/system/vault.service

cat << 'EOC' | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets" Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID 
KillMode=process 
KillSignal=SIGINT 
Restart=on-failure 
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOC

echo "Enabling service…"

sudo systemctl enable vault.service

sleep 5

sudo systemctl start vault

sleep 5

cd /home/$USER

vault operator init | sudo tee /home/$USER/vault_init

sudo chmod 600 /home/$USER/vault_init

root_token=$(sudo cat ~/vault_init | grep "Initial Root Token" | cut -d ":" -f 2 | cut -d " " -f 2)

export VAULT_TOKEN=$root_token

export VAULT_ADDR=https://vault.local.test:8200

echo -ne "\n\nexport VAULT_TOKEN=$root_token" >> ~/.bashrc

echo -ne "\n\nexport VAULT_ADDR=https://vault.local.test:8200" >> ~/.bashrc

sleep 5

echo "Vault successfully installed after $SECONDS seconds…"

sleep 5

exit 0