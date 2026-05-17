# ansible-openscap-pipeline

An automated security configuration management pipeline that integrates OpenSCAP compliance scanning with Ansible-driven remediation on Ubuntu 22.04. The pipeline ingests OpenSCAP scan results, maps findings to targeted Ansible roles, executes remediation, and produces a before/after comparison report to quantify the hardening impact.

---

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1. SCAN                                                      │
│  oscap xccdf eval → ARF + HTML output (pre-remediation)      │
├─────────────────────────────────────────────────────────────┤
│  2. PARSE                                                     │
│  scripts/parse_results.py → failing rule IDs → role map      │
├─────────────────────────────────────────────────────────────┤
│  3. REMEDIATE                                                 │
│  Ansible roles: ssh_hardening · password_policy ·            │
│                 filesystem_hardening · audit_logging          │
├─────────────────────────────────────────────────────────────┤
│  4. RE-SCAN                                                   │
│  oscap xccdf eval → ARF + HTML output (post-remediation)     │
├─────────────────────────────────────────────────────────────┤
│  5. REPORT                                                    │
│  scripts/compare_reports.py → score delta + pass/fail diff   │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Category | Tools |
|---|---|
| Configuration Management | Ansible, Ansible Roles |
| Compliance Scanning | OpenSCAP (`oscap`), SCAP Security Guide (SSG) |
| Compliance Profile | CIS Ubuntu 22.04 Level 1 |
| Target OS | Ubuntu 22.04 LTS |
| CI/CD | GitHub Actions |
| Reporting | XCCDF/ARF/HTML, Markdown diff report |
| Infrastructure / Lab | Vagrant, VirtualBox |

---

## Repository Structure

```
.
├── Vagrantfile                  # Ubuntu 22.04 lab VM definition
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts.ini
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
│   ├── run_scan.sh              # Execute oscap scan and save output
│   ├── parse_results.py         # Parse ARF XML → structured findings
│   └── compare_reports.py       # Diff two ARF files → Markdown report
├── reports/
│   ├── pre-remediation/
│   ├── post-remediation/
│   └── comparison/
├── tests/
│   └── fixtures/                # Sample ARF files for parser unit tests
├── pipeline.sh                  # Single-command pipeline entrypoint
├── .github/
│   └── workflows/
│       └── ansible-validate.yml # Lint + syntax check on push/PR
└── docs/
    ├── architecture.md
    ├── compliance-profile.md
    ├── scanning.md
    ├── baseline-findings.md
    ├── usage.md
    ├── remediation-runbooks.md
    └── sample-report.md
```

---

## Ansible Roles

| Role | Controls Targeted |
|---|---|
| `ssh_hardening` | Root login disabled, password auth off, `MaxAuthTries`, idle timeout |
| `password_policy` | Password age policy (`login.defs`), PAM `pam_pwquality` complexity |
| `filesystem_hardening` | `nodev`/`nosuid`/`noexec` on `/tmp` and `/dev/shm`, unused filesystem modules disabled |
| `audit_logging` | `auditd` enabled, rules for privileged commands, file deletion, user/group changes |

Each role maps its tasks to specific OpenSCAP rule IDs. See `config/rule_role_map.yml` for the full mapping.

---

## Prerequisites

- [Vagrant](https://developer.hashicorp.com/vagrant/install) >= 2.3
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) >= 7.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14
- [ansible-lint](https://ansible.readthedocs.io/projects/lint/) — `pip install ansible-lint`
- [Python](https://www.python.org/) >= 3.9 (for parser scripts)

---

## Quick Start

```bash
# 1. Start the lab VM
vagrant up

# 2. Verify Ansible connectivity
ansible targets -m ping

# 3. Run the full pipeline
./pipeline.sh
```

The pipeline will:
1. Run a baseline OpenSCAP scan and save results to `reports/pre-remediation/`
2. Parse failing rules and determine which roles to apply
3. Execute the relevant Ansible roles
4. Re-scan and save results to `reports/post-remediation/`
5. Generate a comparison report in `reports/comparison/`

---

## Running Scanners Individually

```bash
# Baseline scan only
source config/scan.env
bash scripts/run_scan.sh

# Parse ARF results
python3 scripts/parse_results.py reports/pre-remediation/latest.arf

# Compare two reports
python3 scripts/compare_reports.py \
  reports/pre-remediation/latest.arf \
  reports/post-remediation/latest.arf

# Apply a single role
ansible-playbook ansible/playbooks/site.yml --tags ssh_hardening
```

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/ansible-validate.yml`) runs on every push and pull request:

- `ansible-lint` — all playbooks and roles
- `ansible-playbook --syntax-check` — `site.yml`
- `yamllint` — all YAML files

![Ansible Validate](https://github.com/hubertwojcik/ansible-openscap-pipeline/actions/workflows/ansible-validate.yml/badge.svg)

---

## Milestones

| # | Milestone | Description |
|---|---|---|
| 1 | Lab & Foundation | Vagrant lab, Ansible project structure, connectivity |
| 2 | Scanning Layer | OpenSCAP + SSG setup, profile selection, baseline scan |
| 3 | Remediation Layer | Ansible roles for SSH, passwords, filesystem, audit |
| 4 | Pipeline Integration | XCCDF parser, full scan → remediate → re-scan chain |
| 5 | Reporting & CI/CD | Before/after report, GitHub Actions validation |

---

## License

MIT
