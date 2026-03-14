# Project Context: Morpheus Enterprise Datacenter Lab

## 🏗️ Architecture & System Environment
This project represents a fully automated, immutable homelab designed to mimic a Fortune 500 enterprise deployment. It is split into an **Out-of-Band Provisioning layer** and an **In-Band Enterprise layer**.

**Hardware Inventory:**
* **DEV Laptop:** Pure thin-client. Hosts the VSCode Dev Container. No infrastructure runs here.
* **Container Host Laptop:** The "Out-of-Band" automation engine. Runs Docker/K3s, HashiCorp Vault, and Semaphore UI.
* **AMD Epyc Server (Management Plane):** Bare-metal Ubuntu running KVM/libvirt. Hosts the heavy Enterprise VMs.
* **3x Intel NUCs (Compute Plane):** Bare-metal nodes running Fedora CoreOS (FCOS) as OpenShift (OKD) workers.

**Enterprise Software Stack:**
* **Out-of-Band Provisioning:** Ansible CLI (Bootstrap) -> Semaphore UI (Continuous IaC).
* **Enterprise Orchestration:** Morpheus Enterprise (Community License).
* **Day-2 Enterprise Automation:** Ansible AWX (Simulating Ansible Automation Platform).
* **Identity/DNS/IPAM:** Microsoft Active Directory & MS DNS.
* **Enterprise Compute:** OKD (OpenShift) with OpenShift Virtualization.

## 🎯 Active Goals: The Master Bootstrapping Sequence
The AI Architect and Coder must work together to scaffold and implement the following execution sequence. 

**Phase 1: The Local Spark (Container Host Laptop)**
* [ ] `bootstrap.sh`: Bash script to install Git, pull this repo, and install Python/Ansible CLI.
* [ ] `playbook-1-host-prep.yml`: Install Docker, K3s, and prepare the local environment.
* [ ] `playbook-2-semaphore-init.yml`: Deploy Semaphore UI and HashiCorp Vault into the local K3s/Docker environment.

**Phase 2: The Hypervisor Foundation (AMD Epyc & NUCs)**
* [ ] `playbook-3-amd-prep.yml`: Install KVM/libvirt and configure Layer 2 networking bridges on the AMD Epyc.
* [ ] `playbook-4-nuc-prep.yml`: Configure Wake-on-LAN and a local web server to host FCOS ignition files for the NUCs.

**Phase 3: The Enterprise Core (Deployed to AMD Epyc KVM)**
* [ ] `playbook-5-identity.yml`: Provision the Windows Server AD/DNS VM. *(Must execute first for DNS resolution)*.
* [ ] `playbook-6-automation.yml`: Deploy Ansible AWX (either as a VM or a lightweight K3s payload).
* [ ] `playbook-7-morpheus.yml`: Provision the Morpheus Appliance VM.

**Phase 4: The Kubernetes Compute Plane**
* [ ] `playbook-8-okd-masters.yml`: Generate the OKD Agent-based ISO and deploy the 3x Control Plane VMs on the AMD Epyc.
* [ ] `playbook-9-okd-workers.yml`: PXE boot/wake the 3x NUCs to pull FCOS and join the OKD cluster as bare-metal workers.

## 📜 Architectural Rules & Constraints
* **The "No SSH" Rule:** Once `bootstrap.sh` is run, no human should ever SSH directly into a server to make changes. All configuration must happen via these Ansible playbooks.
* **Separation of Automation Duties:** * **Semaphore UI** is strictly the "Factory." It builds and manages the underlying infrastructure (VMs, hypervisors, K8s clusters) defined in the playbooks above.
    * **Ansible AWX** is strictly the "Product." It is integrated into Morpheus for Day-2 enterprise operations (e.g., configuring payloads running *inside* the OKD cluster).
* **Idempotency:** All Ansible playbooks must be highly idempotent. The entire suite should be able to run against the lab repeatedly without breaking healthy infrastructure.
* **Storage Constraints:** OpenShift Virtualization VMs require RWX storage. The AMD Epyc server will host the NFS/iSCSI targets to enable VM Live Migration across the NUCs.

## 🤖 AI Workflow Directives
* **The Architect (Gemini CLI):** Responsible for reading this file, scaffolding the directory structure, creating blank playbook files based on the Active Goals, and updating the state of this `GEMINI.md` file using markdown checkboxes. Do not write complex Ansible logic.
* **The Coder (Gemini Code Assist / IDE):** Responsible for implementing the actual Ansible tasks, Jinja2 templates, and configurations inside the scaffolded files. Must strictly adhere to the architecture and sequence defined above.