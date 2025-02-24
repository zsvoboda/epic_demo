#!/bin/bash

sudo mkdir -p $MOUNT_ROOT
sudo chmod 777 $MOUNT_ROOT
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/EXCHANGE $MOUNT_ROOT

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo rm -rf $MOUNT_ROOT/export
    sudo rm -rf $MOUNT_ROOT/import
fi

if [ "$1" = "setup" ]; then
    sudo mkdir $MOUNT_ROOT/export
    sudo chown 1001:1001 $MOUNT_ROOT/export
    sudo chmod 744 $MOUNT_ROOT/export
    sudo mkdir $MOUNT_ROOT/import
    sudo chown 1001:1001 $MOUNT_ROOT/import
    sudo chmod 777 $MOUNT_ROOT/import
fi

sudo umount $MOUNT_ROOT