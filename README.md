# ansible-openscap-pipeline

An automated security compliance pipeline that provisions two Ubuntu 22.04 EC2 instances on AWS, runs an OpenSCAP baseline scan across both, applies Ansible-driven remediation in parallel, re-scans, and produces a before/after comparison report to quantify the hardening impact.

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
│  2. OpenSCAP scan BEFORE  (both targets in parallel)
│     → reports/pre-remediation/target-{1,2}.html
│
│  3. ansible-playbook remediate.yml  (both targets in parallel)
│     → ssh_hardening · password_policy · filesystem_hardening · audit_logging
│
│  4. OpenSCAP scan AFTER  (both targets in parallel)
│     → reports/post-remediation/target-{1,2}.html
│
│  5. compare_reports.py
│     → reports/comparison/delta.md  (score + pass/fail diff per host)
│     → uploaded as GitHub Actions artifact
│
└  6. terraform destroy
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions runner                                       │
│  (ubuntu-latest — Ansible control node)                     │
│                                                             │
│  terraform apply / destroy                                  │
│  ansible-playbook site.yml                                  │
│  python3 scripts/compare_reports.py                         │
└──────────────────┬──────────────────────────────────────────┘
                   │ SSH (port 22)
                   │
        ┌──────────▼──────────────────────┐
        │         AWS eu-north-1          │
        │                                 │
        │  VPC  ──  Public Subnet         │
        │  │                              │
        │  ├── EC2 target-1 (t3.micro)   │
        │  │   Ubuntu 22.04               │
        │  │   OpenSCAP + SSG             │
        │  │                              │
        │  └── EC2 target-2 (t3.micro)   │
        │      Ubuntu 22.04               │
        │      OpenSCAP + SSG             │
        │                                 │
        │  Security Group: SSH 0.0.0.0/0  │
        └─────────────────────────────────┘
```

---

## Tech Stack

| Category | Tools |
|---|---|
| Infrastructure | Terraform, AWS EC2 (Ubuntu 22.04, t3.micro) |
| Configuration Management | Ansible, Ansible Roles |
| Compliance Scanning | OpenSCAP (`oscap`), SCAP Security Guide (SSG) |
| Compliance Profile | CIS Ubuntu 22.04 Level 1 |
| Target OS | Ubuntu 22.04 LTS (×2 EC2 instances) |
| CI/CD | GitHub Actions (also acts as Ansible control node) |
| Reporting | XCCDF/ARF/HTML, Markdown diff report |

---

## Repository Structure

```
.
├── terraform/
│   ├── main.tf                  # Wires all modules together
│   ├── variables.tf
│   ├── outputs.tf               # EC2 public IPs, generated inventory
│   ├── backend.tf               # S3 state backend
│   ├── provider.tf
│   └── modules/
│       ├── encryption/          # KMS key for S3/DynamoDB
│       ├── backend/             # S3 bucket + DynamoDB state lock
│       ├── vpc/                 # VPC, subnet, IGW, route table
│       ├── security-groups/     # SG: SSH from anywhere (GHA dynamic IPs)
│       └── compute/             # 2x EC2 target nodes + key pair
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts.ini            # Generated from terraform output
│   ├── playbooks/
│   │   └── site.yml             # Top-level orchestration playbook
│   └── roles/
│       ├── ssh_hardening/
│       ├── password_policy/
│       ├── filesystem_hardening/
│       └── audit_logging/
├── config/
│   ├── scan.env                 # PROFILE_ID and DATASTREAM_PATH
│   └── rule_role_map.yml        # OpenSCAP rule ID → Ansible role mapping
├── scripts/
│   ├── run_scan.sh              # Execute oscap scan on target and fetch output
│   ├── parse_results.py         # Parse ARF XML → structured findings
│   └── compare_reports.py       # Diff two ARF files → Markdown report
├── reports/
│   ├── pre-remediation/
│   ├── post-remediation/
│   └── comparison/
├── .github/
│   └── workflows/
│       ├── pipeline.yml         # Full pipeline: provision → scan → remediate → report
│       └── ansible-validate.yml # Lint + syntax check on PR
└── docs/
```

---

## Ansible Roles

| Role | Controls Targeted |
|---|---|
| `ssh_hardening` | Root login disabled, password auth off, `MaxAuthTries`, idle timeout |
| `password_policy` | Password age policy (`login.defs`), PAM `pam_pwquality` complexity |
| `filesystem_hardening` | `nodev`/`nosuid`/`noexec` on `/tmp` and `/dev/shm`, unused filesystem modules disabled |
| `audit_logging` | `auditd` enabled, rules for privileged commands, file deletion, user/group changes |

---

## Prerequisites

- AWS credentials configured as GitHub Secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- EC2 SSH private key stored as GitHub Secret: `EC2_SSH_PRIVATE_KEY`
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5 (local, for manual runs)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14 (local, for manual runs)
- [ansible-lint](https://ansible.readthedocs.io/projects/lint/) — `pip install ansible-lint`
- [Python](https://www.python.org/) >= 3.9

---

## Quick Start (manual)

```bash
# 1. Provision EC2 targets
cd terraform/
terraform init
terraform apply
cd ..

# 2. Generate Ansible inventory from Terraform output
terraform -chdir=terraform/ output -raw inventory > ansible/inventory/hosts.ini

# 3. Verify connectivity to both targets
ansible targets -m ping

# 4. Run the full pipeline
./pipeline.sh

# 5. Tear down
terraform -chdir=terraform/ destroy
```

---

## CI/CD

Two GitHub Actions workflows:

**`pipeline.yml`** — triggered manually (`workflow_dispatch`) or on push to `main`:
1. `terraform apply` — provisions 2x EC2 targets
2. OpenSCAP pre-scan on both targets
3. Ansible remediation on both targets
4. OpenSCAP post-scan on both targets
5. Generate comparison report → upload as artifact
6. `terraform destroy` — cleans up EC2

**`ansible-validate.yml`** — triggered on every PR:
- `ansible-lint` — all playbooks and roles
- `ansible-playbook --syntax-check` — `site.yml`
- `yamllint` — all YAML files

![Ansible Validate](https://github.com/hubertwojcik/ansible-openscap-pipeline/actions/workflows/ansible-validate.yml/badge.svg)

---

## Milestones

| # | Milestone | Description |
|---|---|---|
| 1 | Infrastructure | Terraform EC2 provisioning, VPC, Security Groups, key pair |
| 2 | Scanning Layer | OpenSCAP + SSG setup, CIS profile selection, baseline scan on both targets |
| 3 | Remediation Layer | Ansible roles: SSH, passwords, filesystem, audit |
| 4 | Pipeline Integration | XCCDF parser, full scan → remediate → re-scan chain in GitHub Actions |
| 5 | Reporting & CI/CD | Before/after comparison report, artifact upload, ansible-validate workflow |

---

## License

MIT
