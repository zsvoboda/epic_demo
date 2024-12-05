#!/bin/sh

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    sudo userdel -rf epic_daemon
    sudo userdel -rf windows_user
    sudo groupdel -f epic_daemons
    sudo groupdel -f windows_users
    exit $?
fi

if [ "$1" = "setup" ]; then
    sudo groupadd --gid 2200 epic_daemons
    sudo useradd --uid 1001 --gid 1001 epic_daemon
    sudo useradd --uid 1002 --gid 1002 windows_user

    exit $?
fi