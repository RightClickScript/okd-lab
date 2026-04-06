# Project Context: Morpheus Enterprise Datacenter Lab

## 🏗️ Architecture & System Environment
Morpheus Enterprise Datacenter Lab: A fully automated, immutable homelab.

### 💻 Container Host (lpt-1) - The "Factory"
*   **Role:** Out-of-Band Automation & Provisioning Hub.
*   **IP:** `192.168.199.5` (br0).
*   **Platform:** K3s (Traefik/ServiceLB disabled).
*   **Networking:** MetalLB v0.14.9 (Layer 2).
*   **Global VIP:** `192.168.199.50` (Traefik Ingress).
*   **Services:** Semaphore UI, HashiCorp Vault, Ansible AWX, Nginx Distribution Hub (Port 8080).

### 🖥️ Management Plane (sms-1) - The "Infrastructure"
*   **Role:** Bare-metal KVM Hypervisor (AMD Epyc).
*   **IP:** `192.168.199.4` (bond0).
*   **Services:** MS AD/DNS VM, Morpheus Appliance VM, OKD Control Plane VMs.

### ⚡ Compute Plane (NUC 1-3) - The "Workload"
*   **Role:** Bare-metal OKD Workers (Intel NUCs).
*   **IPs:** `192.168.199.1-3`.
*   **OS:** Fedora CoreOS (FCOS).

---

## 🎯 The Consolidated Bootstrapping Sequence

### Phase 1: The Local Spark (Container Host Laptop)
- [x] `playbook-1-host-prep.yml`: Kernel modules (`br_netfilter`, `overlay`), Sysctl tweaks, and K3s installation.
- [x] `playbook-2-infrastructure-core.yml`: MetalLB v0.14.9 deployment & Traefik Ingress on VIP `192.168.199.50`.
- [x] `playbook-3-semaphore-factory.yml`: Semaphore UI deployment with RBAC Cluster-Admin and Idempotent API Seeding.
- [ ] `playbook-4-vault-deploy.yml`: Deploy HashiCorp Vault (Launched from Semaphore).
- [ ] `playbook-5-awx-deploy.yml`: Deploy Ansible AWX (Launched from Semaphore).

### Phase 2: The Hypervisor Foundation (SMS-1 & NUCs)
- [ ] `playbook-3-amd-prep-part1.yml`: Sanitization & Networking on SMS-1 (via Semaphore).
- [ ] `playbook-3-amd-prep-part2.yml`: KVM/libvirt & Storage on SMS-1 (via Semaphore).
- [ ] `playbook-4-nuc-prep.yml`: Wake-on-LAN & FCOS Ignition web server (via Semaphore).

### Phase 3: The Enterprise Core (Deployed to SMS-1 KVM)
- [ ] `playbook-5-identity.yml`: Provision the Windows Server AD/DNS VM.
- [ ] `playbook-7-morpheus.yml`: Provision the Morpheus Appliance VM.

### Phase 4: The Kubernetes Compute Plane
- [ ] `playbook-8-okd-masters.yml`: OKD Control Plane VMs on SMS-1.
- [ ] `playbook-9-okd-workers.yml`: OKD Bare-metal Workers on NUCs.

---

## 📜 Architectural Rules & Networking Truths
*   **MetalLB Version:** Use **v0.14.9** ONLY. v0.15.x has known ARP/Routing issues on this hardware.
*   **K3s Networking:** Traefik and ServiceLB must be disabled in `k3s.service` flags to allow Helm-controlled ingress.
*   **Ingress Routing:** Access all factory services via `192.168.199.50` with the following hostnames:
    *   `semaphore.homelab.local`
    *   `dist.homelab.local`
    *   `vault.homelab.local` (Pending)
    *   `awx.homelab.local` (Pending)
*   **RBAC Policy:** The Semaphore ServiceAccount has `cluster-admin` rights. Playbooks run from the UI do NOT need external Kubeconfigs.
*   **The "No SSH" Rule:** All configuration beyond the initial `bootstrap.sh` must be executed via Ansible/Semaphore.
*   **Idempotency:** Playbook 3 (Seeding) is the standard for idempotency: it cleans duplicates and only adds missing resources via the API.
