#!/bin/sh

if [ "$#" != "1" -o -z "$1" ]; then
    echo "Usage: $0 setup"
    echo "       $0 cleanup"
    exit 1
fi

if [ "$1" = "cleanup" ]; then
    ssh "root@${FA_CONTROLLER_IP}" bash << 'EOS'

# Active Directory
puread puread account delete EpicActiveDirectory

# Delete local users
pureds local user delete epic_daemon
pureds local user delete zsvoboda

# Delete local groups
pureds local group delete epic_daemons

# Detach and remove the NFS export policy 
purepolicy nfs remove --dir fs_epic:md_epic_exchange p_exchange_anonymous_nfs
purepolicy nfs remove --dir fs_epic:md_epic_exchange p_exchange_nfs
purepolicy nfs delete p_exchange_anonymous_nfs
purepolicy nfs delete p_exchange_nfs

# Detach and remove the SMB share policy
purepolicy smb remove --dir fs_epic:md_epic_exchange p_exchange_anonymous_smb
purepolicy smb delete p_exchange_anonymous_smb
purepolicy smb remove --dir fs_epic:md_epic_exchange p_exchange_smb
purepolicy smb delete p_exchange_smb

# Delete the managed directory
puredir delete fs_epic:md_epic_exchange

# Delete and eradicate the filesystem
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

# Active Directory
puread account create --domain "c14-dom-a-ad1.local" --join-ou "CN=Computers" --tls required --computer-name "EpicFA" "EpicActiveDirectory"

# Local groups
pureds local group create --gid 2100 epic_daemons

# Local users
{ echo 'password'; echo 'password'; } | pureds local user create --password --uid 2101 --primary-group epic_daemons epic_daemon
{ echo 'password'; echo 'password'; } | pureds local user create --password --uid 502 --primary-group Administrators zsvoboda

# Filesystem
purefs create fs_epic

# Managed directory
puredir create --path /home fs_epic:md_epic_exchange

# NFS export policy
purepolicy nfs create --disable-user-mapping p_exchange_anonymous_nfs
purepolicy nfs rule add --client "*" --all-squash --anonuid 2101 --anongid 2100 --version nfsv3 p_exchange_anonymous_nfs

purepolicy nfs create --disable-user-mapping p_exchange_nfs
purepolicy nfs rule add --client "*" --all-squash --anonuid 2101 --anongid 2100 --version nfsv3 p_exchange_nfs

# NFS export
purepolicy nfs add --dir fs_epic:md_epic_exchange --export-name EXCHANGE_ANONYMOUS p_exchange_anonymous_nfs
purepolicy nfs add --dir fs_epic:md_epic_exchange --export-name EXCHANGE p_exchange_nfs

# SMB share policy
purepolicy smb create p_exchange_anonymous_smb
purepolicy smb rule add --client "*" --anonymous-access-allowed p_exchange_anonymous_smb
purepolicy smb create p_exchange_smb
purepolicy smb rule add --client "*" p_exchange_smb

# SMB share
purepolicy smb add --dir fs_epic:md_epic_exchange --export-name EXCHANGE_ANONYMOUS p_exchange_anonymous_smb
purepolicy smb add --dir fs_epic:md_epic_exchange --export-name EXCHANGE p_exchange_smb

# restore stdout from fd3
exec 1>&3
EOS

exit $?
fi