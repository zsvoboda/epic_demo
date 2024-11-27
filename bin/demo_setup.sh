#!/bin/bash

sudo mkdir -p /mnt/epic_exchange_anonymous
sudo chmod 777 /mnt/epic_exchange_anonymous
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/EXCHANGE_ANONYMOUS /mnt/epic_exchange_anonymous/

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo rm -rf /mnt/epic_exchange_anonymous/export
    sudo rm -rf /mnt/epic_exchange_anonymous/import
fi

if [ "$1" = "setup" ]; then
    sudo mkdir /mnt/epic_exchange_anonymous/export
    sudo chown 2101:2100 /mnt/epic_exchange_anonymous/export
    sudo chmod 744 /mnt/epic_exchange_anonymous/export
    sudo mkdir /mnt/epic_exchange_anonymous/import
    sudo chown 2101:2100 /mnt/epic_exchange_anonymous/import
    sudo chmod 777 /mnt/epic_exchange_anonymous/import
fi

sudo umount /mnt/epic_exchange_anonymous