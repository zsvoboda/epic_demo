#!/bin/sh

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo userdel -f epic_daemon_1
    sudo userdel -f epic_daemon_2
    sudo groupdel -f epic_daemons
    exit $?
fi

if [ "$1" = "setup" ]; then
    sudo groupadd --gid 2200 epic_daemons
    sudo adduser --no-create-home --uid 2201 --gid 2200 epic_daemon_1
    sudo adduser --no-create-home --uid 2202 --gid 2200 epic_daemon_2

    exit $?
fi


