# AI_WORKFLOW.md: The Dual-Agent Strategy

This project utilizes a **Dual-Agent AI Workflow** to bridge the gap between high-level infrastructure design and low-level code implementation. We separate labor between two distinct Gemini instances to prevent context drift and ensure architectural integrity.

## 🏗️ 1. The Concept

We divide responsibilities based on the strengths of the Gemini interfaces:

* **The Architect (Gemini CLI):**
* **Role:** Infrastructure & State Management.
* **Responsibilities:** Maintains `GEMINI.md` (the Source of Truth), manages the filesystem (scaffolding), and executes shell operations (`kubectl`, `lxc`, `git`).


* **The Coder (Gemini Code Assist / GCA):**
* **Role:** Logic & Implementation.
* **Responsibilities:** Lives in the IDE (VS Code), writes code, refactors, and generates unit tests based on the boundaries set by the Architect.



---

## 🛠️ 2. Scaffolding a New Project

To initiate this workflow in a new repo, follow these three steps:

1. **Initialize Context:** Create a `GEMINI.md` file at the root. (See template in Section 5).
2. **Seed the Architect (CLI):** Run the **Architect Seed Prompt** in your terminal.
3. **Seed the Coder (GCA):** Paste the **Coder Seed Prompt** into the VS Code Gemini Chat (ensure **Agent Mode** is ON).

---

## 📝 3. Seed Prompts

### Architect Seed (For Gemini CLI)

> "System Prompt: You are the Senior Architect. Your primary responsibility is maintaining the `GEMINI.md` file as our Source of Truth. You manage directory structures, run shell commands (Kubectl/LXC/Docker), and verify infrastructure compatibility. You do not write application logic; you only scaffold files and update the project state."

### Coder Seed (For GCA / IDE)

> "System Prompt: You are the Senior Software Engineer. Your source of truth is the `GEMINI.md` file. Before writing any code, read the 'Active Goals' and 'Architectural Rules' in `GEMINI.md`. Your focus is on writing high-quality code and unit tests within the existing directory structure."

---

## 🔄 4. Detailed Execution Example

*Scenario: Developing a Node.js application to test Kubernetes Leases on your OKD cluster.*

### Step A: The Architect's Design (Terminal)

**User Input:** `gemini "Architect: Plan a Node.js app in /services/lease-tester. Update GEMINI.md with the goal of verifying K8s Lease behavior in our LXD-hosted OKD. Create the directory, a blank index.js, and a Dockerfile."`

**Result:** 1. The CLI creates the `/services/lease-tester` directory.
2. It writes the technical specs into `GEMINI.md`.
3. It creates the blank files.
4. **The "State" is now set.**

### Step B: The Coder's Implementation (IDE)

**User Action:** Open `index.js` in VS Code.
**GCA Prompt:** `"Coder: Based on the goals in GEMINI.md, implement the Node.js logic for the Lease Tester. It must attempt to acquire a lease and log the status. Ensure it uses the Node.js version and K8s client library standard for our stack."`

**Result:** 1. GCA reads the rules in `GEMINI.md`.
2. It writes the logic, knowing exactly which dependencies to use.
3. It populates the Dockerfile for the AMD EPYC architecture.

### Step C: Verification & State Sync (Terminal)

**User Input:** `gemini "Architect: Review the work in /services/lease-tester. If valid, update GEMINI.md to mark this task as 'Complete' and commit the changes."`

---

## 🧠 5. GEMINI.md Template (The Shared Context)

*Create this file at the root of your repo.*

```markdown
# Project Context: [Project Name]

## 🖥️ System Environment
* **Hardware:** [e.g., AMD EPYC 128GB, 3 Intel NUCs]
* **Platform:** [e.g., OKD on LXD/LXC]

## 🎯 Active Goals
1. [Goal 1: e.g., Set up Node.js Lease Tester]

## 📜 Architectural Rules
* **Infra:** Use Groovy for Morpheus, Helm for K8s.
* **Constraints:** Manifests must be compatible with LXC (no nested virt).
* **Workdir:** All work occurs within the VS Code Dev Container.

```

---

**Would you like me to help you create a "Sync Script" that you can run in your terminal to instantly push IDE changes back to the Architect's context?**
