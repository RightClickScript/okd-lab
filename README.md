# Morpheus Enterprise Datacenter Lab

This project automates the setup of an immutable, enterprise-grade homelab using Ansible, Docker, K3s, and Morpheus.

## 🏗️ Infrastructure Architecture

```mermaid
graph TD
    subgraph "Local Spark (Container Host Laptop)"
        LPT[Laptop: 192.168.199.5]
        LPT --- DOCKER[Docker Engine]
        LPT --- K3S[K3s Cluster]
        DOCKER --- SEM[Semaphore UI: 3000]
        K3S --- VLT[HashiCorp Vault: 30002]
        K3S --- AWX[Ansible AWX: 30005]
    end

    subgraph "Management Plane (AMD Epyc)"
        SMS[SuperMicro SMS: 192.168.199.4]
        SMS --- KVM[KVM / Libvirt]
        KVM --- AD[MS AD / DNS VM]
        KVM --- MORPH[Morpheus Appliance VM]
        KVM --- OKD_M[OKD Master VMs]
    end

    subgraph "Compute Plane (Intel NUCs)"
        NUC1[NUC 1: 192.168.199.1]
        NUC2[NUC 2: 192.168.199.2]
        NUC3[NUC 3: 192.168.199.3]
        NUC1 & NUC2 & NUC3 --- FCOS[Fedora CoreOS]
        FCOS --- OKD_W[OKD Bare-metal Workers]
    end

    subgraph "Networking (VLAN Standard)"
        V199[VLAN 199: Management / Untagged]
        V198[VLAN 198: VM & OKD / Tagged]
        LPT & SMS & NUC1 & NUC2 & NUC3 --- V199
        SMS & NUC1 & NUC2 & NUC3 --- V198
    end
```

## 🚀 Infrastructure Factory Services (Phase 1)

These services are hosted on the **Container Host Laptop** (192.168.199.5).

| Service | Access URL | Default Credentials |
| :--- | :--- | :--- |
| **Semaphore UI** | [http://192.168.199.5:3000](http://192.168.199.5:3000) | `bishop` / `Admin@12345` |
| **HashiCorp Vault UI** | [http://192.168.199.5:30002](http://192.168.199.5:30002) | (Requires Unseal Keys / Root Token) |
| **Ansible AWX UI** | [http://192.168.199.5:30005](http://192.168.199.5:30005) | `admin` / `Admin@12345` |

## 🛠️ Troubleshooting

### Resetting Semaphore Admin Password
If you're unable to log in to Semaphore, you can create a new admin user inside the container:
```bash
sudo docker exec -it bishop_semaphore-semaphore-1 semaphore user add --admin --name "Architect" --login "admin" --email "admin@homelab.local" --password "Admin@12345"
```

### Initializing and Unsealing Vault
Vault is initially **SEALED**. Run these commands on the laptop to initialize it:
```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl exec -n vault -it vault-0 -- vault operator init
```
*Note: Securely save the Unseal Keys and Root Token provided by the output.*

### Monitoring AWX Deployment
AWX can take 5-10 minutes to initialize. Monitor the progress:
```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get pods -n awx -w
```

## 📜 Architectural Source of Truth
Refer to **`GEMINI.md`** for the full hardware inventory, networking standard, and bootstrapping sequence.
