#!/bin/bash

if [[ $# -eq 0 ]]
  then
    echo "No arguments supplied"
    exit 1
elif ! [[ $# -ge 1 ]]
  then
    echo "Script has at least 1 arguments: $0 <server | client>"
    exit 1
fi

type=$1

if ! [[ -d /tmp/hashicorp ]]
  then
    mkdir -p /tmp/hashicorp
fi

cd /tmp/hashicorp

export NOMAD_VERSION="1.2.3"

echo "Downloading Nomad…"

curl --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip

echo "Unzipping package…"

unzip nomad_${NOMAD_VERSION}_linux_amd64.zip

sudo chown root:root nomad

sudo mv nomad /usr/local/bin/

nomad -autocomplete-install

complete -C /usr/local/bin/nomad nomad

sudo mkdir --parents /opt/nomad /var/log/nomad

echo "Creating nomad system user…"

sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad

sudo chown --recursive nomad:nomad /opt/nomad /var/log/nomad

sudo mkdir --parents /etc/nomad.d

sudo chmod 700 /etc/nomad.d

sudo touch /etc/nomad.d/nomad.hcl

echo "Adding configuration files…"

cat << EOA | sudo tee /etc/nomad.d/nomad.hcl
datacenter = "dc1"
data_dir = "/opt/nomad"

log_file = "/var/log/nomad/nomad.log"

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
  disable_hostname           = true
}
EOA

if [[ $type = "server" ]]
  then
    sudo touch /etc/nomad.d/server.hcl

    sudo chown --recursive nomad:nomad /etc/nomad.d

    encryption_key=$(openssl rand -base64 32)

    cat << EOB | sudo tee /etc/nomad.d/server.hcl
bind_addr = "0.0.0.0"

server {
  enabled = true
  bootstrap_expect = 1
  encrypt = "$encryption_key"
}
EOB

    sudo touch /etc/systemd/system/nomad.service
    cat << 'EOC' | sudo tee /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
User=nomad
Group=nomad
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=5
StartLimitIntervalSec=10s
TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOC
  else
    sudo touch /etc/nomad.d/client.hcl

    sudo chown --recursive nomad:nomad /etc/nomad.d

    cat << EOD | sudo tee /etc/nomad.d/client.hcl
client {
  enabled = true
}
EOD

    sudo touch /etc/systemd/system/nomad.service
    cat << 'EOE' | sudo tee /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOE
fi

echo "Enabling service…"

sudo systemctl enable nomad

sleep 5

sudo systemctl start nomad

sleep 5

echo "Nomad successfully installed after $SECONDS seconds…"

sleep 5

exit 0

