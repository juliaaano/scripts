#!/bin/bash

set -euxo pipefail

MACHINE_NAME=$1

docker-machine create --driver virtualbox --virtualbox-memory "2048" $MACHINE_NAME
docker-machine kill $MACHINE_NAME
VBoxManage modifyvm $MACHINE_NAME --usbxhci on
VBoxManage usbfilter add 2 --target $MACHINE_NAME --name Yubikey --active yes --vendorid 1050 --productid 0116 --revision 0349
docker-machine start $MACHINE_NAME

