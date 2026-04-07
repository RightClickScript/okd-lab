# GEMINI.md - Infrastructure Source of Truth

## 🏗️ Architecture & System Environment
Morpheus Enterprise Datacenter Lab: A fully automated, immutable homelab.

### Current Stable State (April 7, 2026 Snapshot)
*   **lpt-1 (Container Host):** OS (Ubuntu), Data (ZFS `datapool`). IP: `192.168.199.5`.
    *   **K3s Status:** Running with `--flannel-iface br0` (MTU 1500 stability).
    *   **Core Services:** Semaphore UI, HashiCorp Vault (Unsealed), Ansible AWX (Live).
    *   **Distro Hub:** Nginx on port 8080 serving `/mnt/data/distribution/`.
*   **sms-1 (AMD Epyc):** OS (Ubuntu), Data (NVMe ZFS `datapool`). IP: `192.168.199.4`.
    *   **Networking:** Standardized via Phase 0 (`br0` Management, `br198` Compute).
    *   **Hypervisor:** KVM/Libvirt running. Cockpit active on port 9090.
    *   **VMs deployed:** `identity-01` (Windows DC), `morpheus-01` (Morpheus Appliance).
*   **NUC 1-3 (Compute):** SCOS installed on bare-metal. IP: `192.168.199.1-3`.
    *   **Networking:** Static configs (`bond0` + `vlan198`) applied via Ignition.

---

## 📜 Hardened Mandates (No Reversion Allowed)
1.  **The "No Revert" Rule:** Do NOT use older fragments of code (e.g., non-bridged Netplan, generic ISO URLs, or local Python hashing).
2.  **K3s MTU Fix:** Must use `--flannel-iface br0` on K3s installation to prevent SSH "Host unreachable" errors.
3.  **Host-Based Execution:** Factory playbooks (Vault, AWX) must run on `hosts: lpt-1` to leverage local `helm` and Python dependencies.
4.  **Static NUC Net:** NUC Ignition MUST use the NetworkManager `bond0` + `vlan198` profiles with URL-encoded content.
5.  **Password Hashing:** Use native Python `crypt` on `lpt-1` instead of Ansible filters to avoid pod dependency issues.

---

## 🎯 Bootstrapping Progress

### Phase 1: The Local Spark (Container Host) - [COMPLETED]
- [x] `playbook-1-host-prep.yml`: K3s Foundation + `br0` stability + `passlib/genisoimage`.
- [x] `playbook-2-infrastructure-core.yml`: MetalLB v0.14.9 & Traefik Ingress.
- [x] `playbook-3-semaphore-factory.yml`: Self-healing UI Seeding.
- [x] `playbook-4-vault-deploy.yml`: Vault deployed and unsealed.
- [x] `playbook-5-awx-deploy.yml`: AWX Operator (v3.2.1) and Instance live.

### Phase 2: The Hypervisor Foundation - [COMPLETED]
- [x] `playbook-3-amd-prep-part1.yml`: SMS-1 Sanitization & Cockpit.
- [x] `playbook-3-amd-prep-part2.yml`: SMS-1 KVM & ZFS Storage.
- [x] `playbook-4-nuc-prep.yml`: NUC Ignition JSON generation (Static Net).

### Phase 3: The Enterprise Core - [IN PROGRESS]
- [x] `playbook-5-identity.yml`: identity-01 (Windows DC) deployed.
- [x] `playbook-7-morpheus.yml`: morpheus-01 (Appliance) deployed.
- [ ] Post-deploy AD config (Join Morpheus to Domain).

### Phase 4: The Kubernetes Compute Plane - [TODO]
- [ ] `playbook-8-okd-masters.yml`: Deploy OKD Masters on SMS-1.
- [ ] `playbook-9-okd-workers.yml`: Trigger NUC join via Worker Ignition.

---

## 🚀 Recent Findings & Corrections
*   **MetalLB ARP:** v0.15.x failed; v0.14.9 fixed communication.
*   **K3s ServiceLB:** Must be disabled to allow MetalLB pool management.
*   **Traefik Ingress:** Requires explicit `Host` headers for IP-based API calls.
*   **UniFi DNS:** Successfully handles `*.homelab.local` resolution to `192.168.199.50`.
*   **MTU Mismatch:** Flannel default MTU (1450) caused SSH drops; `--flannel-iface br0` on host fixed it.
*   **ZFS Mountpoints:** Must use `extra_zfs_properties` in Ansible `zfs` module for `mountpoint`.
*   **Windows VM Lifecycle:** Use `--import` in `virt-install` to prevent shutdown after stage-1 install.
