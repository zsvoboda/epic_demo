#!/bin/bash

sudo mkdir -p /mnt/epic
sudo chmod 777 /mnt/epic
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/EXCHANGE /mnt/epic/

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo rm -rf /mnt/epic/export
    sudo rm -rf /mnt/epic/import
fi

if [ "$1" = "setup" ]; then
    sudo mkdir /mnt/epic/export
    sudo chown 1001:1001 /mnt/epic/export
    sudo chmod 744 /mnt/epic/export
    sudo mkdir /mnt/epic/import
    sudo chown 1001:1001 /mnt/epic/import
    sudo chmod 777 /mnt/epic/import
fi

sudo umount /mnt/epic