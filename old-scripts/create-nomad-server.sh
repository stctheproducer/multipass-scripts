#!/bin/bash

cd scripts

working_dir=$(pwd)

./install-docker.sh

cd $working_dir

./install-consul.sh server

cd $working_dir

./install-nomad.sh server

cd $working_dir

./cleanup.sh

exit 0