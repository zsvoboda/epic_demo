#!/bin/sh

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    ssh "root@${FA_CONTROLLER_IP}" bash << 'EOS'

# Delete local users
pureds local user delete epic_daemon
pureds local user delete windows_user

# Delete local groups
pureds local group delete epic_daemons
pureds local group delete windows_users

# Detach and remove the NFS export policy 
purepolicy nfs remove --dir epic_file_system:epic_managed_directory nfs_epic_daemon_access_policy
purepolicy nfs delete nfs_epic_daemon_access_policy

# Detach and remove the SMB share policy
purepolicy smb remove --dir epic_file_system:epic_managed_directory smb_windows_user_access_policy
purepolicy smb delete smb_windows_user_access_policy

# Delete the managed directory
puredir delete epic_file_system:epic_managed_directory

# Delete and eradicate the filesystem
purefs destroy epic_file_system
purefs eradicate epic_file_system

EOS
    exit $?
fi

if [ "$1" = "setup" ]; then

ssh "root@${FA_CONTROLLER_IP}" bash << 'EOS'

set -eu
set -o pipefail

# backup original stdout to fd3 and redirect stdout to stderr
exec 3>&1
exec 1>&2

# Local groups
pureds local group create --gid 1001 epic_daemons
pureds local group create --gid 1002 windows_users

# Local users
{ echo 'password'; echo 'password'; } | pureds local user create --password --uid 1001 --primary-group epic_daemons epic_daemon
{ echo 'password'; echo 'password'; } | pureds local user create --password --uid 1002 --primary-group windows_users windows_user

# Filesystem
purefs create epic_file_system

# Managed directory
puredir create --path /home epic_file_system:epic_managed_directory

# NFS export policy
purepolicy nfs create --disable-user-mapping nfs_epic_daemon_access_policy
purepolicy nfs rule add --client "*" --all-squash --anonuid 1001 --anongid 1001 --version nfsv3 nfs_epic_daemon_access_policy

# NFS export
purepolicy nfs add --dir epic_file_system:epic_managed_directory --export-name EXCHANGE nfs_epic_daemon_access_policy

# SMB share policy
purepolicy smb create smb_windows_user_access_policy
purepolicy smb rule add --client "*" smb_windows_user_access_policy

# SMB share
purepolicy smb add --dir epic_file_system:epic_managed_directory --export-name EXCHANGE smb_windows_user_access_policy

# restore stdout from fd3
exec 1>&3
EOS

exit $?
fi