#!/bin/bash
set -e

echo Cleanup...
sudo apt-get -y autoremove
sudo apt-get -y clean

sudo rm -rf /tmp/*
# rm -rf /ops