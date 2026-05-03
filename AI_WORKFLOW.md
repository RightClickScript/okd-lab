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
*   **OS:** CentOS Stream CoreOS (SCOS).

---

## 🎯 Bootstrapping Sequence Status

### Phase 1: The Local Spark (Container Host Laptop) - [COMPLETED]
- [x] K3s Installation & Sysctl tweaks.
- [x] MetalLB v0.14.9 & Traefik Ingress.
- [x] Semaphore UI deployment.
- [x] HashiCorp Vault deployment.
- [x] Ansible AWX deployment.

### Phase 2: The Hypervisor Foundation - [COMPLETED]
- [x] SMS-1 & NUCs Bare-metal Prep (KVM, ZFS, Libvirt).
- [x] Ignition server & configurations.

### Phase 3: The Enterprise Core - [COMPLETED]
- [x] Windows Server AD/DNS VM Provisioned.
- [x] Morpheus Appliance VM Provisioned.
- [x] HAProxy Load Balancer Configured (`192.168.199.60`).

### Phase 4: The Kubernetes Compute Plane - [IN PROGRESS]
- [x] OKD Control Plane (Masters) on SMS-1.
- [x] OKD Workers on NUCs.
- [x] Cluster Bootstrapping & DNS Wildcard resolution (`*.apps.okd.homelab.local`).
- [x] Active Directory Auth Integration.
- [🔄] **Phase 4.4: OpenShift Virtualization (KubeVirt) & Storage (Currently Refining)**.

---

## 🚀 Key Discoveries & Hardened Fixes (Lessons Learned)

During the deployment of OpenShift Virtualization and OKD network configuration, we encountered several complex issues that fundamentally changed our architectural approach.

### 1. The Dual-NIC Architectural Shift (The Ultimate Fix)
*   **The Problem:** Applying NMState policies (`NodeNetworkConfigurationPolicy`) to create a bridge on a single-NIC node (`enp1s0`) caused the node to temporarily drop its static IP and fall back to DHCP. This broke HAProxy routing and caused NMState's own probes to panic and rollback the configuration.
*   **The Solution:** We upgraded the entire cluster to an **Enterprise Dual-NIC Architecture**. Every OKD VM is now deployed via `virt-install` with two network interfaces:
    *   `enp1s0` (Management): Handles cluster API traffic and retains the static IP.
    *   `enp2s0` (Virtualization): Exclusively used by NMState to form the external bridge. No IP address is assigned to it, making it a pure Layer 2 switch for guest VMs.

### 2. Nested Virtualization & MAC Spoofing
*   **The Problem:** Guest VMs (like Fedora) inside the OKD cluster could not obtain DHCP addresses from the physical UniFi router. The Libvirt hypervisor on the physical NUCs detected the guest VM's MAC address coming out of the SCOS worker VM's interface and dropped the packets as "MAC Spoofing."
*   **The Solution:** Added `trustGuestRxFilters=yes` to the `virt-install` network definitions for all OKD VMs. This puts the virtual interfaces into promiscuous mode, allowing nested VM traffic to flow out to the physical network.

### 3. KubeVirt Operator InstallModes
*   **The Problem:** The KubeVirt Operator (`community-kubevirt-hyperconverged`) failed to install via OLM with the error `OwnNamespace InstallModeType not supported`.
*   **The Solution:** The KubeVirt operator requires cluster-wide privileges. We removed the `targetNamespaces` array from the `OperatorGroup` YAML, which defaults the group to `AllNamespaces` mode, allowing the operator to deploy successfully.

### 4. Bridge Identity Crisis (`br-ex` vs `br-ext`)
*   **The Problem:** OKD's internal OVN-Kubernetes CNI reserves a bridge named `br-ex` as an Open vSwitch (OVS) interface. Creating a standard Linux bridge named `br-ex` via NMState caused CNI conflicts and prevented the `virt-launcher` pods from starting.
*   **The Solution:** Renamed our external Linux bridge to `br-ext` to safely sidestep internal OVN naming conventions.

### 5. HAProxy Health Check Failures (`<NOSRV>`)
*   **The Problem:** Operators like `console` and `authentication` were reporting `EOF` errors. HAProxy logs showed backend workers as `DOWN` with Layer 4 timeouts, despite the nodes being online.
*   **The Solution:** OKD ingress routers use specific TLS handshakes. Using standard `check` on port 443 in HAProxy caused verification failures. We updated the HAProxy backend configuration to use basic TCP port checks (`check port 443` and `check port 80`) without enforcing SSL verification.

### 6. HAProxy WebSocket Timeouts (Console Flashing)
*   **The Problem:** The OKD Web Console VNC viewer for VMs would constantly disconnect and "flash" every 50 seconds.
*   **The Solution:** Added `timeout tunnel 3600s` to the `defaults` section of HAProxy to allow long-lived WebSocket connections for VM consoles.

### 7. Post-Deployment API Rollout Panic
*   **The Problem:** Immediately after bootstrap, `oc get clusteroperators` shows critical operators (Console, Auth, Monitoring) as Degraded.
*   **The Solution:** This is normal post-bootstrap behavior. The `kube-apiserver` is rolling out new revisions (e.g., from rev 8 to 9). Wait for all `installer` pods to complete and `guard` pods to stabilize in the `openshift-kube-apiserver` namespace before assuming failure.

### 8. Active Directory LDAP Path Alignment
*   **The Problem:** OKD AD Auth integration failed with "Invalid Credentials" because it was trying to bind to the default `CN=Users` folder using the root `Administrator` account, which did not align with our provisioned Lab OU architecture. Furthermore, the LDAP URL lacked the `?sub` suffix, preventing recursive searches for users.
*   **The Solution:** Updated the `OAuth` configuration to bind securely using our dedicated service account (`CN=okd_admin,OU=Lab,DC=homelab,DC=local`) and search the correct base (`OU=Lab,DC=homelab,DC=local`). Added the `?sub` flag to the URL to enable nested searching, and granted `cluster-admin` RBAC rights directly to the `okd_admin` user.

---
*This document tracks the evolving state and the architectural decisions required to stabilize the nested virtualization environment.*