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

echo "Creating NomadServer instance…"

multipass launch -n NomadServer -vvvv --cloud-init cloud-init.yml

# echo 'Waiting for instance to be created…'

# wait_for_minutes $minutes

echo 'Copying scripts to NomadServer instance…'

multipass exec NomadServer -- mkdir scripts

for file in $(ls scripts)
  do
    multipass transfer -vvvv scripts/$file NomadServer:scripts
done

multipass exec NomadServer -- chmod +x scripts/*.sh

echo 'Initializing Nomad server…'

multipass exec NomadServer -- scripts/create-nomad-server.sh

echo "Finsihed creating NomadServer in $SECONDS seconds."

sleep 5

exit 0

