#!/bin/sh

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo deluser epic_daemon_1
    sudo deluser epic_daemon_2
    sudo delgroup epic_daemons
    exit $?
fi

if [ "$1" = "setup" ]; then
    sudo addgroup --gid 2200 epic_daemons

    sudo adduser --no-create-home --disabled-password  --uid 2201 --gid 2200 epic_daemon_1
    sudo adduser --no-create-home --disabled-password  --uid 2202 --gid 2200 epic_daemon_2

    exit $?
fi


