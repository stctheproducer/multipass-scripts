#!/usr/bin/bash
set -euo pipefail

sudo apt-get update -y
export DEBIAN_FRONTEND=noninteractive

echo "# Installing mkcert…"
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert

mkcert -install

echo "# Installing Hashicorp vault..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/hashicorp-agent.gpg

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" -y

sudo apt-get update

sudo apt-get install vault -y

sudo usermod -aG vault $USER