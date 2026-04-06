# GEMINI.md - Infrastructure Source of Truth

## 🏗️ Architecture & System Environment
Morpheus Enterprise Datacenter Lab: A fully automated, immutable homelab.

### Hardware Inventory & Disk Mapping
*   **lpt-1 (Container Host):** OS (sda / ext4), Data (sdb / ZFS `datapool`). `192.168.199.5`.
*   **sms-1 (AMD Epyc):** OS (sda / ext4), Data (nvme0n1 / ZFS `datapool`). `192.168.199.4`.
*   **NUC 1-3 (Compute):** OS (nvme0n1 / SCOS), Data (sda / ext4). `192.168.199.1-3`.

### Networking Standard
*   **Management Plane:** VLAN 199 (192.168.199.0/24).
*   **Compute Plane:** VLAN 198 (192.168.198.0/24).
*   **LoadBalancer Pool:** 192.168.199.50 - 192.168.199.60.
*   **Primary Ingress VIP:** `192.168.199.50` (Traefik).
*   **DNS:** Primary `192.168.1.1` (UniFi), secondary `192.168.199.4` (MS AD/DNS - Pending).
*   **Domain:** `homelab.local`.

---

## 📜 Architectural Rules
*   **The "No SSH" Rule:** All configuration via Ansible/Semaphore. No manual SSH allowed.
*   **Stable MetalLB:** Use v0.14.9 for guaranteed ARP stability on this hardware.
*   **Ingress Standard:** All factory tools route via `192.168.199.50` with unique hostnames.
*   **Self-Healing Seeding:** Seeding logic must be idempotent and clean up duplicates.

---

## 🎯 Bootstrapping Status

### Phase 1: The Local Spark (Container Host Laptop)
- [x] `playbook-1-host-prep.yml`: Kernel, Sysctl, K3s Foundation.
- [x] `playbook-2-infrastructure-core.yml`: MetalLB v0.14.9 & Traefik Ingress.
- [x] `playbook-3-semaphore-factory.yml`: Semaphore UI & RBAC Seeding.
- [ ] `playbook-4-vault-deploy.yml`: Deploy HashiCorp Vault.
- [ ] `playbook-5-awx-deploy.yml`: Deploy Ansible AWX.

### Phase 2: The Hypervisor Foundation (SMS-1 & NUCs)
- [ ] `playbook-3-amd-prep-part1.yml`: SMS-1 Networking & Sanitization.
- [ ] `playbook-3-amd-prep-part2.yml`: SMS-1 KVM & Storage.
- [ ] `playbook-4-nuc-prep.yml`: NUC WOL & FCOS Web Hub.

### Phase 3: The Enterprise Core (SMS-1 KVM)
- [ ] `playbook-5-identity.yml`: MS AD/DNS VM.
- [ ] `playbook-7-morpheus.yml`: Morpheus Appliance VM.

### Phase 4: The Kubernetes Compute Plane
- [ ] `playbook-8-okd-masters.yml`: OKD Control Plane VMs.
- [ ] `playbook-9-okd-workers.yml`: OKD Bare-metal Workers.

---

## 🚀 Recent Findings & Corrections
*   **MetalLB ARP:** v0.15.x failed; v0.14.9 fixed communication.
*   **K3s ServiceLB:** Must be disabled to allow MetalLB pool management.
*   **Traefik Ingress:** Requires explicit `Host` headers for IP-based API calls.
*   **UniFi DNS:** Successfully handles `*.homelab.local` resolution to `192.168.199.50`.
