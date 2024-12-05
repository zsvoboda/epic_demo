# Pure Storage Epic Demo

This demo illustrates a simple scenario of Windows users interacting with the Epic application. Users can seamlessly **import files into Epic** (e.g., PDF documents) and **export files from Epic** (e.g., CSV files) through a shared FlashArray-managed directory. This shared directory supports **multiprotocol access**, enabling communication via both an **NFSv3 mount** (for Epic application daemons on Linux servers) and an **SMB mapped drive** (for Windows users). The key objective is to demonstrate how Epic servers (Linux) and Windows users can collaboratively access and interact with the same share for reading and writing files.

---

## Use Case Examples

1. **File Upload and Import into Epic:**
   - A Windows user uploads a file to the shared directory via SMB.
   - The user logs into the Epic server (Linux) and initiates an import operation using the Epic application.
   - Epic backend daemons process the request, read the file from the shared directory (via NFS), and import it into the Epic application.
     - The Epic application is simulated by a simple bash script that reads the imported file and outputs its content to the console.

2. **File Export from Epic and Access on Windows:**
   - A user logs into the Epic server (Linux) and runs a menu command to export data (e.g., a CSV file) from the Epic application.
   - Epic backend daemons write the exported CSV file to the shared directory (via NFS).
   - The user switches to a Windows workstation and retrieves the CSV file from the shared directory via SMB.

---

## Environment Details

- All users are authenticated against Local users and groups.
- Epic servers use low-numbered UIDs/GIDs (e.g., 1000, 1001, 1002).
- Users on Epic servers interact via a text-based menu in the Epic application, with backend operations performed by Epic daemons using similarly low-numbered UIDs (e.g., 1000, 1001).

**NOTE**: This demo uses FlashArray local users and groups for authentication purposes. If needed, Active Directory can be used for authentication without impacting functionality.

---

## Demo Introduction

### File System and Managed Directory Setup

The demo creates a file system called `epic_file_system` with a managed directory called `epic_managed_directory`.

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

The managed directory contains two subdirectories:

- `import`: Where Windows users copy files for importing into Epic.
- `export`: Where Windows users access files exported from Epic.

Permissions for both directories are configured from the Epic (Linux) side using the `chmod` command.

See the [`./bin/demo_setup.sh`](./bin/demo_setup.sh) script for more details.

### Users and Groups

The demo utilizes local users for NFS access. All NFS access from Epic daemons (with UIDs around 1000) are squashed (`all-squash`) to a single user called `epic_daemon` (UID: 1001). This user is a member of the `epic_daemons` local group (GID: 1001).

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

### NFS Export Policy and Export

The `nfs_epic_daemon_access_policy` NFS export policy is defined on the FlashArray:

The policy utilizes the `all-squash` NFS export option, impersonating every user's access as the `epic_daemon` user (UID: 1001). User mapping is disabled, meaning access from Epic Linux daemons is not authenticated. This can be easily modified to enable user mapping. In that case, ensure that users with all daemon UIDs are defined in the FlashArray's local user database.

The policy uses the NFSv3 protocol. NFSv4.1 can also be used if required.

The policy is attached to the `epic_managed_directory` managed directory, resulting in the `EXCHANGE` NFS export.

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

### SMB Export Policy and Export

The `smb_windows_user_access_policy` SMB export policies is defined.

The SMB policy is attached to the `epic_managed_directory` managed directory, resulting in the `EXCHANGE` SMB export.

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

---

## Prerequisites

1. A Linux machine (using GNU/Linux in this example) to simulate the Epic application and daemons.
2. A Windows machine to simulate the end user's workstation.
3. A FlashArray with File Services enabled, and File Virtual Network Interface enabled.

## Demo Setup

1. SSH to the Linux machine that will simulate the Epic application (both the application and daemons are simulated from this machine).

2. Clone this repository:

```bash
git clone https://github.com/zsvoboda/epic_demo.git
```

3. Edit and source the [./bin/env.sh](./bin/env.sh)

```bash
cd epic_demo
. ./bin/env.sh
```

4. Set up the FlashArray (local users and groups, NFS and SMB policies and exports):

```bash
cd epic_demo
./bin/fa/fa_setup.sh setup
```

5. Set up the demo environment (`import` and `export` directories and their permissions):

```bash
cd epic_demo
./bin/demo_setup.sh setup
```

## Executing the Demo

1. SSH to the Linux machine simulating the Epic application.

2. Navigate to the repository directory and execute the Epic export simulation:

```bash
cd epic_demo
./bin/demo.sh export
```

This simulates the Epic application exporting a file by creating an `demo_export.csv` file with sample content in the shared `export` directory.

3. On the Windows machine, map the FlashArray share via SMB:

- In Windows Explorer, right-click on This PC, select "Map network drive...", and enter `\\192.168.1.60\EXCHANGE` in the "Folder:" field. Check the "Connect using different credentials" box and provide the user credentials (`domain\windows_user`). The mapped directory should contain both `import` and `export` subdirectories. Observe the directory and file permissions (ACLs), which are translated from the Linux mode bits set during the demo setup (refer to [./bin/demo_setup.sh](./bin/demo_setup.sh) for details).

4. Open the `export\demo_export.csv` file using a text editor (e.g., Notepad) to simulate a Windows user accessing an exported file from Epic.

5. Create a new file named `import_demo.txt` within the `import` directory and add some text content. This simulates a user uploading a file to Epic.

6. Return to the Linux machine, navigate to the repository directory, and execute the Epic import simulation:

```bash
cd epic_demo
./bin/demo.sh import
```

The content of the `import/import_demo.txt` file created in the previous step should be displayed on the console, simulating the Epic application importing the file.

## Summary
This demo illustrates how FlashArray File Services can effectively and securely handle mixed-protocol environments, making it a suitable storage solution for applications like Epic that require multiprotocol access and seamless cross-platform collaboration.

For any questions or comments regarding this demo, please contact zsvoboda@purestorage.com.