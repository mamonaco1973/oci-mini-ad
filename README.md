# OCI Mini Active Directory

This project deploys a fully functional Active Directory environment on OCI in minutes using Terraform, Samba 4, and automated configuration scripts. It is designed as a low-cost alternative to managed directory services for labs, demos, and development environments.

![diagram](oci-mini-directory.png)


An Ubuntu-based OCI compute instance acts as both a Domain Controller and DNS server, integrated into a custom VCN with secure networking and OCI Bastion Service for private instance access. Windows and Linux instances are also deployed and automatically join the domain at boot, enabling seamless AD authentication across platforms.

This solution is **not intended for production use**, but provides a complete, repeatable environment for testing AD-connected workloads on OCI.

---

## Limitations

While the mini-AD deployment provides a functional and cost-effective Active Directory environment for labs and development, it does not include many of the advanced features found in a managed directory service. Key gaps include:

- **High Availability** — Single domain controller with no redundancy or failover.
- **Automated Backups** — No built-in backup or point-in-time recovery.
- **Automatic Patching** — OS and Samba updates require manual intervention.
- **GPO Replication** — Samba GPO support is limited; no automatic replication.
- **PowerShell AD Cmdlets** — Samba lacks native AD Web Services; many cmdlets do not work.
- **Production Security Hardening** — Security posture depends entirely on your configuration.

---

## Prerequisites

- An OCI account with available Always Free resources
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) configured with a DEFAULT profile in `~/.oci/config`
- [Terraform](https://developer.hashicorp.com/terraform/install) (latest)
- `jq` installed in PATH

---

## Download this Repository

```bash
git clone https://github.com/mamonaco1973/oci-mini-ad.git
cd oci-mini-ad
```

---

## Build the Code

Run `check_env.sh` to validate your environment, then run `apply.sh` to provision the infrastructure.

```bash
export OCI_COMPARTMENT_ID=<your-compartment-ocid>   # optional; falls back to tenancy OCID
./apply.sh
```

The deploy runs in two phases:

1. **01-directory** — VCN, subnets, bastion, and the Samba 4 DC. Waits 10 minutes after the DC instance is created before updating DHCP options, allowing the DC to fully bootstrap.
2. **02-servers** — Linux and Windows client instances that domain-join at first boot.

Total build time is approximately 15–20 minutes end to end.

---

## Build Results

When the deployment completes, the following resources are created:

**Networking:**
- VCN with public subnets (vm-subnet-1, vm-subnet-2) and a private subnet (ad-subnet)
- Internet Gateway and NAT Gateway for controlled outbound access
- Route tables for both public and private subnets
- Security lists for client and DC traffic

**Active Directory:**
- Ubuntu 24.04 ARM64 instance (VM.Standard.A1.Flex, always-free) running Samba 4 as a Domain Controller
- Private subnet placement — no public IP
- VCN DHCP options updated to point DNS at the DC after provisioning

**Secrets:**
- OCI Vault (DEFAULT type) with an AES-256 master key
- All AD account passwords stored as named secrets (`mini-ad-<user>`)
- Retrieved via `./get_password.sh` using the OCI CLI — passwords are not stored in tfstate

**Bastion:**
- OCI Bastion Service (STANDARD, free) for SSH access to the private DC

**Client Instances:**
- Ubuntu 24.04 Linux instance (VM.Standard.E4.Flex) joined to the domain
- Windows Server 2022 instance (VM.Standard.E4.Flex) joined to the domain

---

## Users and Groups

The following sample users and groups are created automatically during DC provisioning.

### Groups

| Group Name   | gidNumber |
|--------------|-----------|
| mcloud-users | 10001     |
| us           | 10002     |
| india        | 10003     |
| linux-admins | 10004     |

### Users

| Username | Full Name   | uidNumber | gidNumber | Groups                           |
|----------|-------------|-----------|-----------|----------------------------------|
| jsmith   | John Smith  | 10001     | 10001     | mcloud-users, us, linux-admins   |
| edavis   | Emily Davis | 10002     | 10001     | mcloud-users, us                 |
| rpatel   | Raj Patel   | 10003     | 10001     | mcloud-users, india, linux-admins|
| akumar   | Amit Kumar  | 10004     | 10001     | mcloud-users, india              |

---

## Connecting to the DC

The DC has no public IP. Use `connect.sh` to create an OCI Bastion port-forwarding session and drop into a shell:

```bash
./connect.sh            # connects to the DC
./connect.sh 10.0.0.x   # connects to any private IP
```

---

## Retrieving Passwords

Passwords are stored in OCI Vault and retrieved via the OCI CLI:

```bash
./get_password.sh admin
./get_password.sh jsmith
./get_password.sh edavis
./get_password.sh rpatel
./get_password.sh akumar
```

Output:
```
Username : jsmith@mcloud.mikecloud.com
Password : <generated-password>
```

Secrets are named `mini-ad-<user>` in the vault and can also be viewed directly in the OCI Console under **Security → Vault**.

---

## Connecting to the Linux Instance

The Linux client has a public IP. SSH directly using the generated key:

```bash
ssh -i 01-directory/keys/Private_Key -o StrictHostKeyChecking=no ubuntu@<linux_public_ip>
```

Run `./validate.sh` to print the DC IP, bastion ID, and connection hints.

---

## Connecting to the Windows Instance

Use the public IP shown in Terraform outputs. Connect via RDP with domain credentials:

- **Username:** `MCLOUD\Admin` or any domain user from the table above
- **Password:** retrieved via `./get_password.sh <user>`

---

## Clean Up

```bash
./destroy.sh
```

Destroys 02-servers first, then 01-directory. All OCI resources are deleted immediately — no retention periods.
