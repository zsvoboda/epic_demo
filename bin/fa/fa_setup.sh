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

{ echo $FA_ADMIN_PASSWORD; echo $FA_ADMIN_PASSWORD; } | ssh "${FA_ADMIN_USER}@${FA_CONTROLLER_IP}" << 'EOS'

pureds local group create --gid 1001 epic_daemons
pureds local group create --gid 1002 windows_users

purefs create epic_file_system

puredir create --path /home epic_file_system:epic_managed_directory

purepolicy nfs create --disable-user-mapping nfs_epic_daemon_access_policy
purepolicy nfs rule add --client "*" --all-squash --anonuid 1001 --anongid 1001 --version nfsv3 nfs_epic_daemon_access_policy

purepolicy nfs add --dir epic_file_system:epic_managed_directory --export-name EXCHANGE nfs_epic_daemon_access_policy

purepolicy smb create smb_windows_user_access_policy
purepolicy smb rule add --client "*" smb_windows_user_access_policy

purepolicy smb add --dir epic_file_system:epic_managed_directory --export-name EXCHANGE smb_windows_user_access_policy

EOS

exit $?
fi