#!/bin/bash

if [[ $# -eq 0 ]]
  then
    echo "No arguments supplied"
    exit 1
elif ! [[ $# -ge 1 ]]
  then
    echo "Script has at least 1 argument: $0 <server | client> <consul server IP>"
    exit 1
fi

type=$1
server_addr=$2
instance_address=$(hostname -I | awk '{print $1}')

if ! [[ -d /tmp/hashicorp ]]
  then
    mkdir -p /tmp/hashicorp
fi

cd /tmp/hashicorp

export CONSUL_VERSION="1.11.1"

export CONSUL_URL="https://releases.hashicorp.com/consul"

echo "Downloading Consul…"

curl --remote-name \
  ${CONSUL_URL}/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

curl --silent --remote-name \
  ${CONSUL_URL}/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS

curl --silent --remote-name \
  ${CONSUL_URL}/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

echo "Unzipping package…"

unzip consul_${CONSUL_VERSION}_linux_amd64.zip

sudo chown root:root consul

sudo mv consul /usr/bin/

consul -autocomplete-install

complete -C /usr/bin/consul consul

sudo mkdir --parents /opt/consul /var/log/consul

echo "Creating consul system user…"

sudo useradd --system --home /etc/consul.d --shell /bin/false consul

sudo chown --recursive consul:consul /opt/consul /var/log/consul

consulkey=$(consul keygen)

sudo mkdir --parents /etc/consul.d

sudo touch /etc/consul.d/{consul.hcl, consul.env}

sudo chown --recursive consul:consul /etc/consul.d

sudo chmod 640 /etc/consul.d/{consul.hcl, consul.env}

echo "Adding configuration files…"

cat << EOA | sudo tee /etc/consul.d/consul.hcl
datacenter = "dc1"
bind_addr = "$instance_address"
client_addr = "0.0.0.0"
data_dir = "/opt/consul"
log_file = "/var/log/consul/consul.log"
EOA
# encrypt = "$consulkey"

if [[ $type = "server" ]]
  then
  sudo touch /etc/consul.d/server.hcl

  sudo chown --recursive consul:consul /etc/consul.d

  sudo chmod 640 /etc/consul.d/server.hcl
  cat << EOB | sudo tee /etc/consul.d/server.hcl
server = true
bootstrap_expect = 1

ui_config {
  enabled = true
}

performance {
  raft_multiplier = 5
}
EOB
  else
  sudo touch /etc/consul.d/client.hcl

  sudo chown --recursive consul:consul /etc/consul.d

  sudo chmod 640 /etc/consul.d/client.hcl
  cat << EOC | sudo tee /etc/consul.d/client.hcl
retry_join = ["$server_addr"]
EOC
fi

sudo touch /etc/systemd/system/consul.service

cat << 'EOD' | sudo tee /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
EnvironmentFile=/etc/consul.d/consul.env
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
EOD

echo "Enabling service…"

sudo systemctl enable consul

sleep 5

sudo systemctl start consul

sleep 5

echo "Consul successfully installed after $SECONDS seconds…"

sleep 5

exit 0
