#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sed -i 's|#force_color_prompt=yes|force_color_prompt=yes|g' .bashrc

echo "# Installing mkcert…"
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert

mkcert -install

echo "# Installing Hashicorp products..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/hashicorp-agent.gpg

# sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" -y

sudo apt update && sudo apt install nomad consul consul-template vault waypoint boundary -y

# echo "# Installing Dnsmasq..."

# sudo apt -y install dnsmasq-base dnsmasq

# echo Configuring Dnsmasq...

# cat <<EOF >/etc/dnsmasq.d/consul
# server=/consul/127.0.0.1#8600
# port=53
# bind-interfaces
# EOF