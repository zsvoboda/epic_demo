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

- Windows users are authenticated against Active Directory.
- Epic servers use low-numbered UIDs/GIDs (e.g., 1000, 1001, 1002).
- Users on Epic servers interact via a text-based menu in the Epic application, with backend operations performed by Epic daemons using similarly low-numbered UIDs (e.g., 1000, 1001).

---

## Demo Introduction

This demo showcases two different scenarios:

- **Authenticated access:** Windows users authenticate against Active Directory.
- **Anonymous access:** The SMB share allows anonymous access.

### File System and Managed Directory Setup

The demo creates a file system called `fs_epic` with a managed directory called `md_epic_exchange`.

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

The managed directory contains two subdirectories:

- `import`: Where Windows users copy files for importing into Epic.
- `export`: Where Windows users access files exported from Epic.

Permissions for both directories are configured from the Epic (Linux) side using the `chmod` command.

See the [`./bin/demo_setup.sh`](./bin/demo_setup.sh) script for more details.

### Users and Groups

The demo utilizes local users for NFS access. All NFS access from Epic daemons (with UIDs around 1000) are squashed (`all-squash`) to a single user called `epic_daemon` (UID: 2101). This user is a member of the `epic_daemons` local group (GID: 2100).

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

The authenticated demo scenario employs Active Directory for SMB authentication.  A user `c14-dom-a-ad1\zsvoboda_ad` (your username and domain will be different) is used, which has no UID and GID (no `uidNumber` and `gidNumber` attributes set in Active Directory).

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

### NFS Export Policies and Exports

Two NFS export policies are defined on the FlashArray:

- `p_exchange_nfs`: For the anonymous access scenario.
- `p_exchange_anonymous_nfs`: For the Active Directory authenticated access scenario.

Currently, both policies are identical. They utilize the `all-squash` NFS export option, impersonating every user's access as the `epic_daemon` user (UID: 2101). User mapping is disabled in both policies, meaning access from Epic Linux daemons is not authenticated. This can be easily modified to enable user mapping. In that case, ensure that users with all daemon UIDs are defined in the FlashArray's local user database or in Active Directory (with the `uidNumber` attribute).

Both export policies use the NFSv3 protocol. NFSv4.1 can also be used if required.

Both policies are attached to the `md_epic_exchange` managed directory, resulting in two NFS exports:

- `EXCHANGE`: NFSv3 export.
- `EXCHANGE_ANONYMOUS`: NFSv3 export.

Currently, these two exports are identical.

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

### SMB Export Policies and Exports

Two SMB export policies are defined:

- `p_exchange_smb`: For the anonymous access scenario.
- `p_exchange_anonymous_smb`:  For the Active Directory authenticated access scenario.

`p_exchange_smb` does not allow anonymous SMB access, while `p_exchange_anonymous_smb` does.

Both SMB policies are attached to the `md_epic_exchange` managed directory, resulting in two SMB exports:

- `EXCHANGE`: SMB export for Active Directory authenticated access.
- `EXCHANGE_ANONYMOUS`: SMB export for anonymous access.

See the [`./bin/fa/fa_setup.sh`](./bin/fa/fa_setup.sh) script for more details.

---

## Prerequisites

1. A Linux machine (using GNU/Linux in this example) to simulate the Epic application and daemons.
2. A Windows machine to simulate the end user's workstation.
3. A FlashArray with File Services enabled, File Virtual Network Interface enabled, and joined to an Active Directory domain.
4. An Active Directory user. The demo uses `c14-dom-a-ad1\zsvoboda_ad`, which has no UID and GID (no `uidNumber` and `gidNumber` attributes set in Active Directory).

## Demo Setup

1. SSH to the Linux machine that will simulate the Epic application (both the application and daemons are simulated from this machine).

2. Clone this repository:

```bash
git clone [https://github.com/zsvoboda/epic_demo.git](https://github.com/zsvoboda/epic_demo.git)
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

This simulates the Epic application exporting a file by creating an `export.csv` file with sample content in the shared `export` directory.

3. On the Windows machine, map the FlashArray share via SMB:

- **For Active Directory authenticated access:** In Windows Explorer, right-click on This PC, select "Map network drive...", and enter `\\192.168.1.60\EXCHANGE` in the "Folder:" field. Check the "Connect using different credentials" box and provide the Active Directory user credentials (`c14-dom-a-ad1\zsvoboda_ad` in this example, but your username and domain will likely differ). The mapped directory should contain both `import` and `export` subdirectories. Observe the directory and file permissions (ACLs), which are translated from the Linux mode bits set during the demo setup (refer to [./bin/demo_setup.sh](./bin/demo_setup.sh) for details).

- **For anonymous access:** In Windows Explorer, right-click on This PC, select "Map network drive...", and enter `\\192.168.1.60\EXCHANGE_ANONYMOUS` in the "Folder:" field. The mapped directory should contain both `import` and `export` subdirectories.  Observe the directory and file permissions, which were set during the demo setup (refer to [./bin/demo_setup.sh](./bin/demo_setup.sh) for details).

**Note:** File and directory permissions will differ between the authenticated and anonymous access methods. 

4. Open the `export\export.csv` file using a text editor (e.g., Notepad) to simulate a Windows user accessing an exported file from Epic.

5. Create a new file named `test.txt` within the `import` directory and add some text content. This simulates a user uploading a file to Epic.

6. Return to the Linux machine, navigate to the repository directory, and execute the Epic import simulation:

```bash
cd epic_demo
./bin/demo.sh import
```

The content of the `import/test.txt` file created in the previous step should be displayed on the console, simulating the Epic application importing the file.

## Summary
This demo illustrates how FlashArray File Services can effectively and securely handle mixed-protocol environments, making it a suitable storage solution for applications like Epic that require multiprotocol access and seamless cross-platform collaboration.

For any questions or comments regarding this demo, please contact zsvoboda@purestorage.com.