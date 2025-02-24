#!/bin/bash

sudo mkdir -p $MOUNT_ROOT
sudo chmod 777 $MOUNT_ROOT
sudo mount -t nfs -o vers=3 ${FA_MOUNT_IP}:/EXCHANGE $MOUNT_ROOT

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 import"
    echo "       $0 export"
    exit 1
fi

if [ "$1" = "import" ]; then
    if [ -d $MOUNT_ROOT/import ]; then
        for FILE in $MOUNT_ROOT/import/*; do
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
    if [ -d $MOUNT_ROOT/export ]; then
        echo "Exported CSV data" > $MOUNT_ROOT/export/demo_export.csv
    else
        echo "Export directory does not exist."
    fi
fi

sudo umount $MOUNT_ROOT