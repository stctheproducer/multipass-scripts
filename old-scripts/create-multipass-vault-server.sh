#!/bin/bash
if [[ $# -eq 0 ]]
  then
  minutes=5
else
  minutes=$1
fi

function wait_for_minutes() {
  timeout=$(expr $1 \* 60)

  echo -ne '\n'

  counter=1
  while [ $counter -lt $timeout ]
    do
      echo -ne '*'
      sleep 1
      ((counter++))
  done

  echo -ne '\n\n'
}

consul_server=$(multipass info NomadServer | grep IPv4 | awk '{print $2}')

echo "Creating node VaultServer instance…"

multipass launch -n VaultServer -vvvv --cloud-init cloud-init.yml

# echo 'Waiting for instance to be created…'

# wait_for_minutes $minutes
echo "Creating TLS certificates…"

mkdir tls && cd $_

cp "$(mkcert -CAROOT)/rootCA.pem" ./vault-ca.pem

mkcert -cert-file vault-cert.pem -key-file vault-key.pem vault.local.test 

cd -

echo "Copy certs to VaultServer instance"

multipass exec VaultServer -- mkdir tls

multipass transfer -vvvv tls/* VaultServer:tls

rm -r tls

echo "Copying scripts to VaultServer instance…"

multipass exec VaultServer -- mkdir scripts

for file in $(ls scripts)
  do
    multipass transfer -vvvv scripts/$file VaultServer:scripts
done

multipass exec VaultServer -- chmod +x scripts/*.sh

echo "Initializing Vault server…"

multipass exec VaultServer -- scripts/create-vault-server.sh $consul_server

echo "Securing vault…"

multipass exec VaultServer - mkdir vault-policies

for file in $(ls files/vault-policies)
  do
    multipass transfer -vvvv files/vault-policies/$file VaultServer:vault-policies
done

multipass exec VaultServer -- chmod +x vault-policies/*.sh

multipass exec VaultServer -- vault-policies/policies.sh

echo "Finsihed creating VaultServer in $SECONDS seconds."

sleep 5

exit 0

