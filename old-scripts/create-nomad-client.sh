#!/bin/bash

if [[ $# -ne 1 ]]
  then
    echo "Please provide the IP address of the consul server(s)"
    exit 1
fi

server_addr=$1

cd scripts

working_dir=$(pwd)

./install-docker.sh

cd $working_dir

./install-consul.sh client $server_addr

cd $working_dir

./install-nomad.sh client

cd $working_dir

./cleanup.sh

exit 0