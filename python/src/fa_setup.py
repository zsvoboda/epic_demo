import os

from pypureclient.flasharray import ReferenceWithType

from flash_array import FlashArray

def setup(fa):

    # Create local groups
    fa.create_local_group(name='epic_daemons',  gid=1001)
    fa.create_local_group(name='windows_users', gid=1002)

    # Create local users
    fa.create_local_user(name='epic_daemon', uid=1001, enabled=True,
                               primary_group=ReferenceWithType(name='epic_daemons'), password='password')
    fa.create_local_user(name='windows_user', uid=1002, enabled=True,
                               primary_group=ReferenceWithType(name='windows_users'), password='password')

    # Create filesystem
    fa.create_file_system('epic_file_system')
    # Create managed directory
    fa.create_managed_directory(name='epic_managed_directory', file_system_name='epic_file_system')

    # Create and add NFS export policy
    fa.create_policy_nfs(name='nfs_epic_daemon_access_policy', disable_user_mapping=True)
    fa.create_policy_nfs_rule(policy_name='nfs_epic_daemon_access_policy', client='*', access='all-squash', anonuid='1001',
                                anongid='1001', nfs_version='nfsv3', security='auth_sys', permission='rw')

    fa.export_managed_directory_nfs(policy_name='nfs_epic_daemon_access_policy',
                                    managed_directory_name='epic_file_system:epic_managed_directory',
                                    export_name='EXCHANGE')

    fa.create_policy_smb(name='smb_windows_user_access_policy')
    fa.create_policy_smb_rule(policy_name='smb_windows_user_access_policy', client='*')
    fa.export_managed_directory_smb(policy_name='smb_windows_user_access_policy',
                                    managed_directory_name='epic_file_system:epic_managed_directory',
                                    export_name='EXCHANGE')

def cleanup(fa):

    # Delete local users
    fa.delete_local_user(name='epic_daemon')
    fa.delete_local_user(name='windows_user')

    # Delete local groups
    fa.delete_local_group(name='epic_daemons')
    fa.delete_local_group(name='windows_users')


    # Delete exports and policies
    fa.delete_export(export_name='EXCHANGE', policy_name='nfs_epic_daemon_access_policy')
    fa.delete_export(export_name='EXCHANGE', policy_name='smb_windows_user_access_policy')

    # Delete managed directories
    fa.delete_managed_directory(name='epic_file_system:epic_managed_directory')
    fa.destroy_file_system(name='epic_file_system')
    fa.eradicate_file_system(name='epic_file_system')

    fa.delete_policy_nfs(name='nfs_epic_daemon_access_policy')
    fa.delete_policy_smb(name='smb_windows_user_access_policy')



# Setup connection to FlashArray
FA_CONTROLLER_IP = '10.31.1.11'
API_TOKEN = os.getenv("FA_TMEFA15_TOKEN")

fa = FlashArray(api_token=API_TOKEN, array_host=FA_CONTROLLER_IP)
fa.authenticate()
setup(fa)
cleanup(fa)
