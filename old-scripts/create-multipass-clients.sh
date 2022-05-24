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

for node in {1..3}
  do
    echo "Creating node NomadClient$node instance…"

    multipass launch -n NomadClient$node -vvvv --cloud-init cloud-init.yml

    # echo 'Waiting for instance to be created…'

    # wait_for_minutes $minutes

    echo "Copying scripts to NomadClient$node instance…"

    multipass exec NomadClient$node -- mkdir scripts

    for file in $(ls scripts)
      do
        multipass transfer -vvvv scripts/$file NomadClient$node:scripts
    done

    multipass exec NomadClient$node -- chmod +x scripts/*.sh

    echo "Initializing Nomad client $node…"

    multipass exec NomadClient$node -- scripts/create-nomad-client.sh $consul_server

    echo "Finsihed creating NomadClient$node in $SECONDS seconds."
    sleep 5
done

exit 0

