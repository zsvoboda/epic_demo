#!/bin/bash

sudo umount /mnt/epic_exchange
sudo mkdir -p /mnt/epic_exchange
sudo chmod 777 /mnt/epic_exchange
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/HOME /mnt/epic_exchange/

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo rm -rf /mnt/epic_exchange/export
    sudo rm -rf /mnt/epic_exchange/import
    exit $?
fi

if [ "$1" = "setup" ]; then
    sudo mkdir /mnt/epic_exchange/export
    sudo chown 2101:2100 /mnt/epic_exchange/export
    sudo mkdir /mnt/epic_exchange/import
    sudo chown 2101:2100 /mnt/epic_exchange/import
    exit $?
fi