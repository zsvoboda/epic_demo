#!/bin/bash

sudo umount /mnt/epic_exchange
sudo mkdir -p /mnt/epic_exchange
sudo chmod 777 /mnt/epic_exchange
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/HOME /mnt/epic_exchange/

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 import"
    echo "       $0 export"
    exit 1
fi

if [ "$1" = "import" ]; then
    if [ -d /mnt/epic_exchange/import ]; then
        for FILE in /mnt/epic_exchange/import/*; do
            if [ -f "$FILE" ]; then
                echo "Importing: $FILE"
                cat "$FILE"
                echo -e "\n------------------------\n"
            fi
        done
    else
        echo "Import directory does not exist."
    fi
fi

if [ "$1" = "export" ]; then
    if [ -d /mnt/epic_exchange/export ]; then
        echo "Demo CSV Content" > /mnt/epic_exchange/export/export.csv
    fi
fi

sudo umount /mnt/epic_exchange