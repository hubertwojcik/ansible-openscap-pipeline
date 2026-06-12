# ansible-openscap-pipeline

An automated security-compliance pipeline that provisions two Ubuntu 22.04 EC2 instances on AWS, runs an OpenSCAP baseline scan, applies Ansible-driven remediation, re-scans, and exposes the before/after reports — so you can quantify the hardening impact against the **CIS Ubuntu 22.04 Level 1** profile.

The pipeline runs entirely in **GitHub Actions** — the runner acts as the Ansible control node, connecting to the EC2 target nodes over SSH.

---

## Pipeline Overview

```
GitHub Actions runner (control node)
│
│  1. terraform apply
│     → EC2 target-1 (Ubuntu 22.04, eu-north-1)
│     → EC2 target-2 (Ubuntu 22.04, eu-north-1)
│
│  2. setup_targets.yml        → install OpenSCAP + SSG on both targets
│
│  3. OpenSCAP scan BEFORE      → reports/pre-remediation/target-{1,2}.{arf.xml,html}
│     (uploaded as artifact: pre-remediation-report)
│
│  4. site.yml                  → 4 hardening roles, both targets
│     ssh_hardening · password_policy · audit_logging · filesystem_hardening
│
│  5. OpenSCAP scan AFTER       → reports/post-remediation/target-{1,2}.{arf.xml,html}
│     (uploaded as artifact: post-remediation-report)
│
└  6. terraform destroy         → always runs (if: always()), no orphaned EC2
```

> Compare the `pre-` and `post-remediation-report` artifacts (open the `.html` in a browser) to see the score improvement. An automated diff report is the next planned step — see [Roadmap](#roadmap).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions runner                                       │
│  (ubuntu-latest — Ansible control node)                     │
│                                                             │
│  terraform apply / destroy   (local state, ephemeral)      │
│  ansible-playbook setup_targets.yml / run_scan.yml / site.yml│
└──────────────────┬──────────────────────────────────────────┘
                   │ SSH (port 22, key auth)
                   │
        ┌──────────▼──────────────────────┐
        │         AWS eu-north-1           │
        │                                  │
        │  VPC  ──  Public Subnet          │
        │   │                              │
        │   ├── EC2 target-1 (t3.micro)    │
        │   │   Ubuntu 22.04               │
        │   │   OpenSCAP + SSG             │
        │   │                              │
        │   └── EC2 target-2 (t3.micro)    │
        │       Ubuntu 22.04               │
        │       OpenSCAP + SSG             │
        │                                  │
        │  Security Group: SSH 0.0.0.0/0   │
        │  (GitHub Actions has dynamic IPs)│
        └──────────────────────────────────┘
```

State note: Terraform uses **local state** (no remote S3 backend). Infrastructure is created and destroyed within a single pipeline run, so the state only needs to live for that run — this keeps the project simple and free of extra S3/KMS/DynamoDB cost.

---

## Tech Stack

| Category | Tools |
|---|---|
| Infrastructure | Terraform, AWS EC2 (Ubuntu 22.04, t3.micro) |
| Configuration Management | Ansible, Ansible Roles |
| Compliance Scanning | OpenSCAP (`oscap`), SCAP Security Guide (SSG) |
| Compliance Profile | CIS Ubuntu 22.04 LTS Level 1 |
| Target OS | Ubuntu 22.04 LTS (×2 EC2 instances) |
| CI/CD | GitHub Actions (also acts as Ansible control node) |
| Reporting | XCCDF / ARF / HTML |

---

## Repository Structure

```
.
├── terraform/
│   ├── main.tf                  # Wires vpc + security-groups + compute
│   ├── variables.tf
│   ├── outputs.tf               # EC2 public IPs, generated inventory
│   ├── provider.tf              # AWS provider (eu-north-1), local state
│   ├── terraform.tfvars
│   └── modules/
│       ├── vpc/                 # VPC, subnet, IGW, route table
│       ├── security-groups/     # SG: SSH from anywhere (GHA dynamic IPs)
│       └── compute/             # 2x EC2 target nodes + key pair + inventory tpl
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts.ini            # Generated from `terraform output`
│   ├── playbooks/
│   │   ├── setup_targets.yml    # Install OpenSCAP + SSG on targets
│   │   ├── run_scan.yml         # Run oscap scan, fetch ARF/HTML back
│   │   └── site.yml             # Apply the 4 hardening roles
│   └── roles/
│       ├── ssh_hardening/
│       ├── password_policy/
│       ├── filesystem_hardening/
│       └── audit_logging/
├── config/
│   └── scan.env                 # PROFILE_ID and DATASTREAM_PATH
├── scripts/
│   └── run_scan.sh              # oscap xccdf eval (copied to targets, run there)
├── reports/
│   ├── pre-remediation/         # ARF + HTML before hardening
│   └── post-remediation/        # ARF + HTML after hardening
├── .github/
│   └── workflows/
│       └── openscap_pipeline.yml # Full pipeline (workflow_dispatch)
├── docs/                        # Step-by-step learning docs (PL) — see docs/00
└── CHANGELOG.md
```

---

## Ansible Roles

| Role | Controls Targeted (CIS L1) |
|---|---|
| `ssh_hardening` | Drop-in `sshd_config.d/00-hardening.conf`: root login off, password auth off, `MaxAuthTries`, idle timeout, X11 off, banner, etc. |
| `password_policy` | Password aging in `/etc/login.defs`; complexity in `/etc/security/pwquality.conf` (minlen 14, digit/upper/lower/special required) |
| `filesystem_hardening` | Unused filesystem modules disabled (cramfs, udf, …); `nodev`/`nosuid`/`noexec` on `/dev/shm` (`/tmp` opt-in) |
| `audit_logging` | `auditd` enabled + rules for identity files, sudoers, time changes, kernel modules, privileged commands |

Each role's variables and every line are explained in `docs/10`–`docs/13`.

---

## Prerequisites

GitHub Secrets (set once — see `docs` / HUB-38):

| Secret | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` | Terraform → AWS (IAM user with EC2/VPC permissions) |
| `AWS_SECRET_ACCESS_KEY` | — |
| `AWS_DEFAULT_REGION` | `eu-north-1` |
| `EC2_SSH_PRIVATE_KEY` | Private key Ansible uses to reach the targets |
| `SSH_PUBLIC_KEY` | Public key deployed to EC2 (mapped to `TF_VAR_ssh_public_key`) |

For local/manual runs:
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14 (`ansible.posix` collection ships with the full `ansible` package)
- [Python](https://www.python.org/) >= 3.9

---

## Running the Pipeline (GitHub Actions)

1. Ensure all five GitHub Secrets above are set.
2. Make sure `openscap_pipeline.yml` is on the **default branch** (`workflow_dispatch` only shows the "Run workflow" button from there).
3. **Actions → "OpenSCAP Pipeline" → Run workflow**.
4. Download results from the run: **Artifacts → `pre-remediation-report` / `post-remediation-report`** (open the `.html` files).

The `terraform destroy` step runs with `if: always()`, so EC2 is torn down even if a scan step fails.

---

## Quick Start (manual, from a laptop)

```bash
# 1. Provision EC2 targets
cd terraform/
export TF_VAR_ssh_public_key="$(cat ~/.ssh/ansible-openscap.pub)"
terraform init
terraform apply

# 2. Generate the Ansible inventory from Terraform output
terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini
cd ../ansible

# 3. Verify connectivity to both targets
ansible targets -m ping

# 4. Install OpenSCAP, scan, remediate, re-scan
ansible-playbook playbooks/setup_targets.yml
ansible-playbook playbooks/run_scan.yml -e scan_phase=pre
ansible-playbook playbooks/site.yml
ansible-playbook playbooks/run_scan.yml -e scan_phase=post
# reports land in reports/{pre,post}-remediation/ — open the .html files

# 5. Tear down (avoid EC2 charges)
cd ../terraform && terraform destroy
```

---

## Milestones

| # | Milestone | Status |
|---|---|---|
| 1 | Infrastructure — Terraform EC2, VPC, Security Groups, key pair | ✅ Done |
| 2 | Scanning Layer — OpenSCAP + SSG, CIS profile, baseline scan | ✅ Done |
| 3 | Remediation Layer — 4 Ansible roles | ✅ Done |
| 4 | Pipeline Integration — full scan → remediate → re-scan in GitHub Actions | ✅ Done |
| 5 | Reporting & CI/CD — before/after comparison report, lint workflow | 🚧 In progress |

---

## Roadmap

Not yet implemented (tracked in Linear):
- `scripts/compare_reports.py` — automated before/after diff (score + per-rule fail→pass) as a Markdown artifact (HUB-29 / HUB-31)
- `.github/workflows/ansible-validate.yml` — `ansible-lint` + `yamllint` + `--syntax-check` on every PR (HUB-32)
- Final architecture & usage docs (HUB-33)

---

## License

MIT
