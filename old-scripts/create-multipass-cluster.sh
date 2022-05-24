#!/bin/bash

./create-multipass-server.sh

sleep 5

./create-multipass-clients.sh

sleep 5

./create-multipass-vault-server.sh

echo "Vault successfully installed after $SECONDS seconds…"

sleep 5

echo "Finished creating cluster after $(expr $SECONDS / 60) minutes."

exit 0