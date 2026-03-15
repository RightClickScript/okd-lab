# GEMINI.md - Infrastructure Source of Truth

## 🏗️ Architecture & System Environment
Morpheus Enterprise Datacenter Lab: A fully automated, immutable homelab.

### Hardware Inventory
* **DEV Laptop:** Thin-client, VSCode Dev Container.
* **Container Host Laptop:** Out-of-Band automation engine (Docker/K3s, Vault, Semaphore UI).
* **AMD Epyc Server:** Management Plane (Ubuntu, KVM/libvirt).
* **3x Intel NUCs:** Compute Plane (FCOS, OKD workers).

### Enterprise Software Stack
* **Provisioning:** Ansible CLI -> Semaphore UI.
* **Orchestration:** Morpheus Enterprise.
* **Day-2 Automation:** Ansible AWX.
* **Identity/DNS/IPAM:** MS AD & DNS.
* **Compute:** OKD (OpenShift) with OpenShift Virtualization.

## 📜 Architectural Rules
* **No SSH:** No manual SSH after `bootstrap.sh`. All config via Ansible.
* **Separation of Duties:** 
    * **Semaphore UI:** The "Factory" (Infrastructure management).
    * **Ansible AWX:** The "Product" (Day-2 operations).
* **Idempotency:** All playbooks must be idempotent.
* **Storage:** AMD Epyc hosts NFS/iSCSI for OKD VM Live Migration.
* **Hardware & Boot Lifecycle Management (The NUC Compute Plane):** We enforce a strict separation between daily power-on events and destructive OS provisioning.
    * **Standard Power-On (Daily Boot):** Handled via Wake-on-LAN. **CRITICAL:** The standard `community.general.wakeonlan` Ansible module silently fails against these Intel NUC NICs. The AI Coder MUST NOT use it. All power-on tasks must use `ansible.builtin.command` to execute the OS-level `wakeonlan {{ mac_address }}` package directly from the Container Host, looping over the inventory MAC variables.
    * **Bare-Metal Provisioning (The "Phoenix" Rebuild):** Handled via Out-of-Band IP-KVM. The NUCs are connected to a GL.iNet IP-KVM (PiKVM fork) on an 8-port switch. Do not build a PXE server for OS deployment. The rebuild playbooks must use the `ansible.builtin.uri` module to hit the KVM's REST API. This API will be used to mount the Fedora CoreOS ISO as virtual media, force a reboot, and inject the necessary BIOS/boot menu hotkeys to automate the fresh installation.


## 🛠️ Day-0 Hardware Readiness (Pre-Bootstrap)

### Prerequisites for Physical Hosts
*   **Operating System:** Ubuntu 22.04+ (LTS preferred) installed on all hosts.
*   **Access:** User `bishop` with `sudo` privileges and SSH key access.
*   **Networking:**
    *   **VLAN 199:** Physical management network (Active).
    *   **VLAN 198:** VM/Compute network (To be configured).
*   **Storage:** All disks are considered "wipable" for fresh initialization.

### "Golden Minimum" OS State (Manual Step)
*   **OS:** Ubuntu Server 22.04/24.04.
*   **User:** `bishop` with passwordless `sudo` and SSH key access.
*   **Packages:** `python3`, `git`.

### Infrastructure Network Standard
*   **Physical Bond:** All hosts will use `bond0` for interface consistency.
*   **Netplan Management:** All existing `/etc/netplan/*.yaml` files will be replaced by a project-managed configuration.
*   **VLAN Mapping:**
    *   **VLAN 199 (192.168.199.0/24):** Physical Management (Untagged/Native or Tagged).
    *   **VLAN 198 (192.168.198.0/24):** VM & OKD Compute (Tagged).


### Host Assignment Table
| Host Role | Physical Name | Management IP | MAC Address |
| :--- | :--- | :--- | :--- |
| **Container Host** | Laptop | 192.168.199.5 | N/A |
| **AMD Epyc** | SMS (SuperMicro) | 192.168.199.4 | 5e:dc:07:8f:3e:01 |
| **NUC 1** | NUC | 192.168.199.1 | 22:27:c6:e0:ab:1a |
| **NUC 2** | NUC | 192.168.199.2 | 02:0f:a8:43:7f:47 |
| **NUC 3** | NUC | 192.168.199.3 | 9e:cb:b7:23:f4:38 |

## 🎯 Master Bootstrapping Sequence

### Phase 0: Pre-Flight Check (Connectivity)
- [x] `playbooks/phase-0/playbook-0-connectivity.yml`: Verify internet connectivity.

### Phase 1: The Local Spark (Container Host Laptop)
- [x] `scripts/bootstrap.sh`: Install Git, Python, Ansible CLI.
- [x] `playbooks/phase-1/playbook-1-host-prep.yml`: Install Docker, K3s.
- [x] `playbooks/phase-1/playbook-2-semaphore-init.yml`: Deploy Semaphore UI.
- [x] `playbooks/phase-1/playbook-2b-vault-init.yml`: Deploy HashiCorp Vault on K3s.
- [x] `playbooks/phase-1/playbook-2c-awx-init.yml`: Deploy Ansible AWX Operator on K3s.

### Phase 2: The Hypervisor Foundation (AMD Epyc & NUCs)
- [ ] `playbooks/phase-2/playbook-3-amd-prep.yml`: KVM/libvirt & L2 Networking on AMD Epyc.
- [ ] `playbooks/phase-2/playbook-4-nuc-prep.yml`: Wake-on-LAN & FCOS Ignition web server.

### Phase 3: The Enterprise Core (AMD Epyc KVM)
- [ ] `playbooks/phase-3/playbook-5-identity.yml`: MS AD/DNS VM.
- [ ] `playbooks/phase-3/playbook-7-morpheus.yml`: Morpheus Appliance VM.

### Phase 4: The Kubernetes Compute Plane
- [ ] `playbooks/phase-4/playbook-8-okd-masters.yml`: OKD Control Plane VMs (AMD Epyc).
- [ ] `playbooks/phase-4/playbook-9-okd-workers.yml`: OKD Bare-metal Workers (NUCs).
