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
pureds local user delete zsvoboda

# Delete local groups
pureds local group delete epic_daemons

# Detach and remove the NFS export policy 
echo "Removing NFS export policy"
purepolicy nfs remove --dir fs_epic:md_epic_exchange p_exchange_dir_nfs
purepolicy nfs delete p_exchange_dir_nfs

# Detach and remove the SMB share policy
echo "Removing SMB share policy"
purepolicy smb remove --dir fs_epic:md_epic_exchange p_exchange_dir_nfs
purepolicy smb delete p_exchange_dir_nfs

# Delete the managed directory
echo "Deleting managed directory"
puredir delete fs_epic:md_epic_exchange

# Delete and eradicate the filesystem
echo "Deleting and eradicating filesystem"
purefs destroy fs_epic
purefs eradicate fs_epic

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
pureds local group create --gid 2100 epic_daemons

# Local users
{ echo 'password'; echo 'password'; } | pureds local user create --password --uid 2101 --primary-group epic_daemons epic_daemon
{ echo 'password'; echo 'password'; } | pureds local user create --password --uid 502 --primary-group zsvoboda zsvoboda

# Filesystem
echo "Creating filesystem"
purefs create fs_epic

# Managed directory
echo "Creating managed directory"
puredir create --path /home fs_epic:md_epic_exchange

# NFS export policy
echo "Creating NFS export policy"
purepolicy nfs create p_exchange_dir_nfs
purepolicy nfs rule add --client "*" --all-squash --anonuid 2101 --anongid 2100 --version nfsv3 p_exchange_dir_nfs

# NFS export
echo "Creating NFS export"
purepolicy nfs add --dir fs_epic:md_epic_exchange --export-name EXCHANGE p_exchange_dir_nfs

# SMB share policy
echo "Creating SMB share policy"
purepolicy smb create p_exchange_dir_smb
purepolicy smb rule add --client "*" --anonymous-access-allowed p_exchange_dir_smb

# SMB share
echo "Creating SMB share"
purepolicy smb add --dir fs_epic:md_epic_exchange --export-name EXCHANGE p_exchange_dir_smb

# restore stdout from fd3
exec 1>&3
EOS

exit $?
fi