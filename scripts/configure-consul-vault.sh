#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if [[ $# -eq 0 ]]
  then
    echo "Script has at least 2 arguments: $0 <datacenter> <leader | follower | client> <node number e.g. 0, 1, 2, 3, 4>"
    exit 1
fi

datacenter=$1
type=$2
node=$3

cd $HOME/consul

if [[ $type = "leader" ]]
  then
  
  gossip_key=$(consul keygen)

  cat << GOSSIP | tee $HOME/consul/gossip_key.json
{
  "gossip_key": "${gossip_key}"
}
GOSSIP

  cat << ACL | sudo tee -a /etc/consul.d/acl.hcl
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
ACL

  sudo sed -i "s|#encrypt = \"...\"|encrypt = \"$gossip_key\"|g" /etc/consul.d/consul.hcl

  echo -e "\nclient_addr = \"0.0.0.0\"" | sudo tee -a /etc/consul.d/server.hcl

cat << UI | sudo tee -a /etc/consul.d/server.hcl

ui_config {
  enabled = true
}
UI

  # Create certificates
  if [[ -d /opt/consul/tls ]]
    then
      sudo rm -rf /opt/consul/tls
  fi
  sudo mkdir -p /opt/consul/tls

  cd /opt/consul/tls

  # Create the certificate authority
  consul tls ca create

  # Create the certificates
  consul tls cert create -server -dc $datacenter
  consul tls cert create -server -dc $datacenter
  consul tls cert create -server -dc $datacenter
  consul tls cert create -server -dc $datacenter
  consul tls cert create -server -dc $datacenter
  
  cd /opt/consul

  sudo chown consul:consul /opt/consul/tls/*.pem
  
  if [[ -e /etc/consul.d/join.hcl ]]
    then
      sudo rm /etc/consul.d/join.hcl
  fi

elif [[ $type = "follower" ]]
  then
    echo -e "\nclient_addr = \"0.0.0.0\"" | sudo tee -a /etc/consul.d/server.hcl

    sudo sed -i "s|server-consul-0.pem|server-consul-$node.pem|g" /etc/consul.d/server.hcl
    sudo sed -i "s|server-consul-0-key.pem|server-consul-$node-key.pem|g" /etc/consul.d/server.hcl
fi

cat << 'SERVICE' | sudo tee /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
EnvironmentFile=-/etc/consul.d/consul.env
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SERVICE

sudo consul validate /etc/consul.d/

echo "Enabling service…"
sudo systemctl enable consul
sleep 5

if [[ $type = "leader" ]]
  then
  sudo systemctl start consul
  echo "Consul successfully started..."
  sleep 5

  cd $HOME/consul

  export CONSUL_CACERT=/opt/consul/tls/consul-agent-ca.pem
  export CONSUL_CLIENT_CERT=/opt/consul/tls/$datacenter-server-consul-0.pem
  export CONSUL_CLIENT_KEY=/opt/consul/tls/$datacenter-server-consul-0-key.pem

  cat << BASH | tee -a $HOME/.bashrc

  export CONSUL_CACERT=/opt/consul/tls/consul-agent-ca.pem
  export CONSUL_CLIENT_CERT=/opt/consul/tls/$datacenter-server-consul-0.pem
  export CONSUL_CLIENT_KEY=/opt/consul/tls/$datacenter-server-consul-0-key.pem
BASH

  consul acl bootstrap  -format=json | jq '{ Token: .SecretID}' > bootstrap_token.json
  chmod 0644 bootstrap_token.json

  export CONSUL_HTTP_TOKEN=$(cat bootstrap_token.json | jq -r '.Token')
  export CONSUL_MGMT_TOKEN=$(cat bootstrap_token.json | jq -r '.Token')

  consul acl policy create -token=${CONSUL_MGMT_TOKEN}   -name node-policy -description "Policy that grants write access for nodes related actions and read access for service related actions" -rules @policies/node-policy.hcl

  consul acl token create -token=${CONSUL_MGMT_TOKEN} -description "Node token" -policy-name node-policy -format json | jq '{ Token: .SecretID}' > payload.json
  chmod 0644 payload.json

  cd $HOME/consul

  # On all Consul Servers
  consul acl set-agent-token -token=$(cat bootstrap_token.json | jq -r '.Token') agent $(cat payload.json | jq -r '.Token')
  elif [[ $type = "follower" ]]
    then
    cat << BASH | tee -a $HOME/.bashrc

  export CONSUL_CACERT=/opt/consul/tls/consul-agent-ca.pem
  export CONSUL_CLIENT_CERT=/opt/consul/tls/$datacenter-server-consul-$node.pem
  export CONSUL_CLIENT_KEY=/opt/consul/tls/$datacenter-server-consul-$node-key.pem
BASH
fi

exit 0

