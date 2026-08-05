# 🏠 Home Lab — Proxmox 3-Node Cluster

> A self-hosted enterprise-grade home lab built on a 3-node Proxmox VE cluster, simulating real-world IT infrastructure for hands-on learning toward Azure, DevOps, and Cloud Security certifications.

---

## 📋 Table of Contents

- [Hardware](#hardware)
- [Network Design](#network-design)
- [Cluster Overview](#cluster-overview)
- [Services & VMs](#services--vms)
- [Active Directory Lab](#active-directory-lab)
- [Firewall — Cisco ASA 5506-X](#firewall--cisco-asa-5506-x)
- [DevOps Workstation](#devops-workstation)
- [Scripts](#scripts)
- [Azure & IaC](#azure--iac)
- [Certifications](#certifications)
- [Roadmap](#roadmap)

---

## Hardware

### Proxmox Cluster Nodes

| Node | Hostname | Hardware | RAM | Role |
|---|---|---|---|---|
| Node 1 (Master) | pve01 | Lenovo Neo50q Gen4 — Intel i5 | 16 GB | Infrastructure & Services — always on |
| Node 2 | pve02 | Lenovo Neo50q Gen4 — Intel i5 | 32 GB | Lab & Learning — Wake-on-LAN |
| Node 3 | pve03 | Lenovo Neo50q Gen4 — Intel i5 | 32 GB | Security & Monitoring — Wake-on-LAN |

### Additional Hardware

| Device | Model | Role |
|---|---|---|
| Firewall | Cisco ASA 5506-X | Physical perimeter firewall — NAT, DHCP, ACLs |
| Switch (pending) | TP-LINK ES208GP v1 Managed L2 PoE+ | 8-port managed L2 switch — VLAN segmentation |
| DevOps Workstation | Dell OptiPlex 3080 | Ubuntu 26.04 LTS — development, automation, IaC |

---

## Network Design

### Current Topology

```
Internet
    │
Home Router (WAN)
    │
Cisco ASA 5506-X (Physical Firewall) ← pending connection
    │  GigabitEthernet 1/1 — WAN (from home router)
    │  GigabitEthernet 1/2 — LAN (10.0.0.1/24)
    │  Management 1/1 — Out-of-band management
    │
Unmanaged Switch
    ├── pve01 (Node 1 — 16GB) — Infrastructure
    │     AdGuard, NGINX, VaultWarden, Twingate
    │
    ├── pve02 (Node 2 — 32GB) — Lab & Learning
    │     Windows Server 2025 DC, Windows 11 Client
    │
    └── pve03 (Node 3 — 32GB) — Security & Monitoring
          Wazuh SIEM, Kali Linux (planned)
```

### Planned Topology (After Managed Switch Deployment)

```
Internet
    │
Home Router (WAN)
    │
Cisco ASA 5506-X
    │
TP-Link TL-SG108E (Managed Switch — VLANs)
    ├── pve01 — VLAN 10 (Management)
    ├── pve02 — VLAN 20 (Servers) + VLAN 30 (Clients)
    └── pve03 — VLAN 40 (Security)
```

### Planned VLAN Design

| VLAN | Name | Subnet | Purpose |
|---|---|---|---|
| 10 | Management | 10.0.10.0/24 | Proxmox nodes, switch access |
| 20 | Servers | 10.0.20.0/24 | Windows Server, Linux VMs |
| 30 | Clients | 10.0.30.0/24 | Domain-joined Windows 11 VMs |
| 40 | Security | 10.0.40.0/24 | Wazuh SIEM, Kali Linux |
| 50 | Home/IoT | 10.0.50.0/24 | Personal devices, isolated |

---

## Cluster Overview

All three nodes run **Proxmox VE 9.2.5** joined into a single cluster:

- Centralised management from one web UI
- Passwordless SSH between all nodes via ed25519 keys
- 3-node quorum — supports HA and live migration
- Wake-on-LAN enabled on pve02 and pve03 (BIOS + OS level)
- No-subscription repos configured on all nodes
- Automated cluster-wide updates via custom bash script

### Key Decisions & Lessons Learned

- `post-up ethtool` for Wake-on-LAN must target the **physical NIC** (`nic0`), not the bridge (`vmbr0`) — the bridge is a software construct that doesn't exist when the machine is powered off
- Proxmox cluster node renaming requires restarting `pve-cluster` immediately after `hostnamectl` — pmxcfs caches the old hostname and must re-resolve
- `/etc/pve/local` is a virtual symlink managed by pmxcfs — `rm` returns permission denied even as root, which is correct behaviour; restart pve-cluster instead
- `pvecm expected 1` is required when running pve01 alone — quorum loss blocks the web UI console

---

## Services & VMs

### Node 1 — pve01 (Infrastructure) — Always On

| Service | Type | Status | Description |
|---|---|---|---|
| AdGuard Home | LXC Container | ✅ Running | Network-wide DNS filtering and ad blocking |
| NGINX Proxy Manager | LXC Container | ✅ Running | Reverse proxy for internal services |
| VaultWarden | LXC Container | ✅ Running | Self-hosted Bitwarden-compatible password manager |
| Twingate Connector 1 | LXC Container | ✅ Running | Zero Trust network access connector |
| Twingate Connector 2 | LXC Container | ✅ Running | Zero Trust network access connector (redundant) |
| Home Assistant | VM | ⏳ Planned | Home automation + node power monitoring |

### Node 2 — pve02 (Lab & Learning) — Wake-on-LAN

| Service | Type | Status | Description |
|---|---|---|---|
| Windows Server 2025 (DC01) | VM | ✅ Running | Active Directory DC, DNS, DHCP — domain: lab.local |
| Windows 11 | VM | ✅ Running | Domain-joined client — GPO and policy testing |
| Ubuntu Server | VM | ⏳ Planned | Docker, scripting, automation |
| Azure AD Connect | Service | ⏳ Planned | Hybrid identity sync to Azure Entra ID |

### Node 3 — pve03 (Security & Monitoring) — Wake-on-LAN

| Service | Type | Status | Description |
|---|---|---|---|
| Wazuh SIEM | VM | ⏳ Planned | Open source SIEM — log collection from all VMs |
| Kali Linux | VM | ⏳ Planned | Security testing and penetration testing |
| Honeypot | VM | ⏳ Planned | Threat detection and attack pattern analysis |

---

## Active Directory Lab

A fully functional Active Directory environment running on **Windows Server 2025** on pve02.

### What's Configured

- Domain Controller promoted on Windows Server 2025 with VirtIO drivers on Proxmox
- Organisational Units — `_Lab > Users, Computers, Groups, Service Accounts, Admins`
- Multiple user accounts across OUs with fine-grained password policies
- **GPOs configured and verified:**
  - Password Policy — 12 char minimum, complexity enabled, 90 day max age
  - Account Lockout — 5 attempts, 15 minute lockout duration
  - Restricted Control Panel and Settings
- DHCP scope configured — 192.168.1.100–200, leases verified on Win11 client
- Windows 11 VM domain-joined and receiving DHCP from DC01
- Proxmox snapshots taken at clean baseline state

### Key Decisions & Lessons Learned

- DNS must point exclusively to the DC before domain join — any other DNS server as primary causes join failure
- IPv6 link-local addresses from home routers silently intercept DNS queries before IPv4 entries — disable IPv6 on the adapter during domain join
- GPO link order determines precedence at the same OU level — lower link order number wins
- `gpresult /r` confirms a GPO was *delivered*, not that its settings are *in effect* — verify with `secpol.msc` too
- Event ID 4740 captures account lockouts — the Caller Computer Name field identifies the source machine

### Break-It Drill — Account Lockout

Intentional lockout test performed to verify policy end-to-end:

1. Entered wrong password 6 times for a domain user on Win11
2. Account locked after 5th attempt (as configured)
3. Verified in AD Users and Computers — lock icon on account
4. Traced via **Event Viewer → Windows Logs → Security → Event ID 4740**
5. Identified Caller Computer Name (source machine) in event details
6. Unlocked account from DC01

---

## Firewall — Cisco ASA 5506-X

A physical Cisco ASA 5506-X positioned between the home router and lab network.

### Configuration

- **GigabitEthernet 1/1** — outside (WAN), DHCP from home router
- **GigabitEthernet 1/2** — inside (LAN), static 10.0.0.1/24
- **Management 1/1** — dedicated out-of-band management
- NAT — dynamic PAT, all lab VMs share home router's public IP
- DHCP server — 10.0.0.10–10.0.0.100 on inside interface
- ACLs — permit inside traffic outbound
- Multiple named configs saved to flash for easy scenario switching

### Key Decisions & Lessons Learned

- Password recovery via ROMMON — `confreg 0x41` to skip startup config, `confreg 0x1` to restore after
- `write erase` only deletes startup-config — the ASA OS image in flash is never affected
- GE MGMT port physically separates management from production traffic — mirrors enterprise best practice

---

## DevOps Workstation

**Lenovo ThinkCentre Neo 50q Gen 4** running **Ubuntu 26.04 LTS** — dedicated development and automation machine.

### Installed Toolchain

| Tool | Version | Purpose |
|---|---|---|
| VS Code | 1.131.0 | Code editor — Terraform, PowerShell, Azure, GitLens, Remote SSH |
| Azure CLI | 2.88.0 | Manage Azure tenant from terminal |
| Terraform | 1.15.8 | Infrastructure as Code |
| Docker Engine | 29.7.1 | Container runtime |
| Python | 3.14.4 | Scripting and automation (isolated venv) |
| Ansible | 2.21.2 | Push configurations to lab nodes |
| PowerShell | 7.6.4 | Azure and AD scripting on Linux |
| Git | Latest | Version control |
| Gitea | Latest | Self-hosted Git server (Docker container) |

### Key Decisions & Lessons Learned

- Python tooling isolated in a venv (`~/devops-env`) — avoids PEP 668 system-wide pip restrictions on Ubuntu 24.04+
- After Ubuntu major version upgrade, venv packages must be reinstalled — Python version changes break existing installations
- Third-party APT repos are renamed to `.list.migrate` during Ubuntu upgrades and must be recreated
- Microsoft packages for Ubuntu 26.04 not yet available — using Ubuntu 24.04 (noble) packages as compatible fallback

---

## Scripts

All scripts version-controlled under `scripts/`.

### `scripts/update-all-nodes.sh`

Updates all three Proxmox nodes via SSH in a single command.

```bash
update-all-nodes
```

### `scripts/wake-lab.sh`

Sends Wake-on-LAN magic packets to Proxmox nodes.

```bash
wake-lab pve01      # wake master node
wake-lab pve02      # wake lab node
wake-lab pve03      # wake security node
wake-lab workers    # wake pve02 and pve03
wake-lab all        # wake entire cluster
```

### `scripts/shutdown-lab.sh`

Cleanly shuts down Proxmox nodes with automatic quorum management.

```bash
shutdown-lab workers    # shut down pve02 and pve03, keep pve01 running
shutdown-lab all        # full cluster shutdown
shutdown-lab pve02      # shut down individual node
```

> `workers` is the everyday command — shuts lab nodes for power saving while keeping infrastructure (AdGuard, NGINX, VaultWarden, Twingate) running on pve01.

---

## Azure & IaC

### Azure

- Free tier tenant connected via Azure CLI
- Azure CLI 2.88.0 authenticated and verified

### Terraform

First IaC deployment — Azure Resource Group provisioned and destroyed via code:

```bash
cd terraform/azure-basics
terraform init
terraform plan
terraform apply    # deploys resource group to West Europe
terraform destroy  # cleans up
```

Provider: `hashicorp/azurerm v3.117.1`

`.gitignore` excludes `.terraform/` provider binaries and state files.

---

## Certifications

| Certification | Status | Target |
|---|---|---|
| AZ-900 Azure Fundamentals | 📚 Studying | Q3 2026 |
| AZ-104 Azure Administrator | 📋 Planned | Q4 2026 |
| SC-300 Identity & Access Administrator | 📋 Planned | Q1 2027 |
| AZ-500 Azure Security Engineer | 📋 Planned | Q2 2027 |
| AZ-400 DevOps Solutions | 📋 Planned | Q3 2027 |
| Terraform Associate | 📋 Planned | 2027 |
| CKA Certified Kubernetes Administrator | 📋 Planned | 2028 |

---

## Roadmap

### In Progress
- [ ] Connect Cisco ASA 5506-X to home router
- [ ] TP-LINK ES208GP v1 Managed L2 PoE+ managed switch — VLAN configuration
- [ ] Home Assistant on pve01 with Shelly plug power monitoring
- [ ] AZ-900 Azure Fundamentals exam

### Next Steps
- [ ] Remaining GPOs — Desktop Wallpaper, Drive Mapping, USB Disable
- [ ] Azure AD Connect — sync lab AD users to Entra ID
- [ ] Wazuh SIEM on pve03 with agents on DC01 and Win11
- [ ] Ubuntu Server VM on pve02
- [ ] Kali Linux VM on pve03
- [ ] Expand Terraform — VNets, NSGs, VMs in Azure
- [ ] Prometheus + Grafana monitoring stack

### Future
- [ ] Kubernetes cluster across pve02 and pve03
- [ ] CI/CD pipeline with Gitea Actions
- [ ] Azure Arc — connect on-prem VMs to Azure management plane
- [ ] Full Zero Trust simulation — Conditional Access, MFA, device compliance

---

## Skills Demonstrated

`Proxmox VE` `Cluster Management` `Active Directory` `Windows Server 2025` `Group Policy` `DNS` `DHCP` `Cisco ASA` `Firewall` `NAT` `ACLs` `ROMMON Recovery` `Wake-on-LAN` `Twingate` `Zero Trust` `Linux` `Ubuntu` `Bash Scripting` `SSH` `Docker` `Terraform` `Azure CLI` `Azure` `IaC` `Git` `Gitea` `Python` `Ansible` `PowerShell` `Identity & Access Management` `Networking` `VirtIO` `Self-hosted Services` `Event Log Analysis` `Security Auditing`

---

*Actively maintained as part of a structured learning path toward a DevOps / Cloud Infrastructure Engineer role.*
