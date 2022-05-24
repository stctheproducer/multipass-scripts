#!/bin/bash

if [[ $# -ne 1 ]]
  then
    echo "Please provide the IP address of the consul server(s)"
    exit 1
fi

server_addr=$1

cd scripts

working_dir=$(pwd)

./install-consul.sh client $server_addr

cd $working_dir

./install-vault.sh $server_addr

cd $working_dir

./cleanup.sh

exit 0