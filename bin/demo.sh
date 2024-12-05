#!/bin/bash

sudo mkdir -p /mnt/epic
sudo chmod 777 /mnt/epic
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/EXCHANGE /mnt/epic/

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 import"
    echo "       $0 export"
    exit 1
fi

if [ "$1" = "import" ]; then
    if [ -d /mnt/epic/import ]; then
        for FILE in /mnt/epic/import/*; do
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
    if [ -d /mnt/epic/export ]; then
        echo "Exported CSV data" > /mnt/epic/export/demo_export.csv
    else
        echo "Export directory does not exist."
    fi
fi

sudo umount /mnt/epic