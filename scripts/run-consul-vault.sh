#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if ! [[ $# -ge 4 ]]
  then
    echo "Script has at least 4 arguments: $0 <datacenter e.g. dc1> <node name e.g. consul> <node type e.g. server | client> <node number e.g. 0, 1, 2, 3, 4> <leader ip address> <encryption key> <agent token | node token>"
    exit 1
fi

datacenter=$1
node_name=$2
node_type=$3
node_number=$4

if [[ $# -ge 5 ]]
  then
    leader_addr=$5
    enc_key=$6
    token=$7
fi

# Rename node and set datacenter
sudo sed -i "s|#datacenter = \"my-dc-1\"|datacenter = \"$datacenter\"|g" /etc/consul.d/consul.hcl

cat << NODE | sudo tee -a /etc/consul.d/consul.hcl

node_name = "$node_name-$node_type-$node_number"
NODE

if [ $node_type = "server" ] && [ $node_number = "0" ]
  then
    type="leader"
elif [ $node_type = "server" ] && [ $node_number -gt 0 ]
  then
    type="follower"
  else
    type="client"
fi

if [ $type = "follower" ] && ! [ $# -eq 7 ]
  then
    echo "Script needs all 7 arguments: $0 <datacenter e.g. dc1> <node name e.g. consul> <node type e.g. server | client> <node number e.g. 0, 1, 2, 3, 4> <leader ip address> <encryption key> <agent token | node token>"
    exit 1
elif [ $type = "client" ] && ! [ $# -eq 7 ]
  then
    echo "Script needs all 7 arguments: $0 <datacenter e.g. dc1> <node name e.g. consul> <node type e.g. server | client> <node number e.g. 0, 1, 2, 3, 4> <leader ip address> <encryption key> <agent token | node token>"
    exit 1
fi

cd $HOME/consul

# Download files
if [[ $node_type = "server" ]]
  then
    curl -L -o server.hcl 'https://raw.githubusercontent.com/stctheproducer/multipass-scripts/develop/templates/dev/consul/server-vault.hcl'
    sudo mv server.hcl /etc/consul.d/server.hcl
    sudo chown consul:consul /etc/consul.d/server.hcl
    sudo chmod 0644 /etc/consul.d/server.hcl
elif [[ $node_type = "client" ]]
  then
    curl -L -o client.hcl 'https://raw.githubusercontent.com/stctheproducer/multipass-scripts/develop/templates/dev/consul/client-vault.hcl'
    sudo mv client.hcl /etc/consul.d/client.hcl
    sudo chown consul:consul /etc/consul.d/client.hcl
    sudo chmod 0644 /etc/consul.d/client.hcl
fi

if [[ $type = "leader" ]]
  then
    if [[ ! -d policies ]]
      then
        mkdir policies
    fi

    curl -L -o policies/node-policy.hcl 'https://raw.githubusercontent.com/stctheproducer/multipass-scripts/develop/policies/consul/node-policy.hcl'

    curl -L -o policies/vault-service-policy.hcl 'https://raw.githubusercontent.com/stctheproducer/multipass-scripts/develop/policies/consul/vault-service-policy.hcl'
  else
    cat << JOIN | sudo tee /etc/consul.d/join.hcl
retry_join = ["$leader_addr"]
JOIN
    sudo chown consul:consul /etc/consul.d/join.hcl
    sudo chmod 0644 /etc/consul.d/join.hcl

    export CONSUL_HTTP_ADDR="http://$leader_addr:8500"

    cat << BASH | tee -a $HOME/.bashrc

export CONSUL_HTTP_ADDR="http://$leader_addr:8500"
BASH
  
    sed -i "s|#encrypt = \"...\"|encrypt = \"$enc_key\"|g" /etc/consul.d/consul.hcl
    
    cat << ACL | sudo tee /etc/consul.d/acl.hcl
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true

  tokens {
    agent = "$token"
  }
}
ACL
fi

if [[ $type = "follower" ]]
then
  cat << ACL | sudo tee /etc/consul.d/acl.hcl
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true

  tokens {
    default = "$token"
  }
}
ACL
fi

# Assign bind address
instance_address=$(hostname -I | awk '{print $1}')
sudo sed -i "s|#bind_addr = \"0.0.0.0\"|bind_addr = \"$instance_address\"|g" /etc/consul.d/consul.hcl

bash configure-consul-vault.sh $datacenter $type $node_number | tee $HOME/configure-consul-vault-output.log







