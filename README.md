# 🛠️ Scripts — Automation Toolkit

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)](https://docs.microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](https://github.com/PowerShell/PowerShell)
[![Author](https://img.shields.io/badge/Author-Kossi%20Eglo-green)](https://github.com/xbiz-cmyk)

> A collection of automation scripts for DevOps, Git workflows, and infrastructure management.

---

## ⚡ TLDR

- 🎮 **Interactive menus** — no need to memorize commands
- 📖 **Built-in explanations** — every option tells you what it does before running
- 🧾 **Command recap** — prints exact commands used so you can learn as you go
- 🔒 **Safety prompts** — destructive actions always ask for confirmation
- 🚀 **Ready to use** — clone and run, no dependencies except git (and optionally `gh`, `terraform`)

---

## 📁 Scripts

| Script | Language | What it does |
|--------|----------|-------------|
| `GitAssistant.ps1` | PowerShell | Full Git workflow assistant — 25 operations with explanations |

---

## 🚀 GitAssistant.ps1

An interactive Git workflow manager. Select operations from a menu — no command memorization needed.

### Quick Start

```powershell
# Clone this repo
git clone https://github.com/xbiz-cmyk/Scripts.git
cd Scripts

# Run the assistant
.\GitAssistant.ps1

# On macOS/Linux (with PowerShell installed)
pwsh GitAssistant.ps1
```

### Features

```
--- Local Repository ---        --- Remote and Sync ---
1.  Initialize (git init)       10. Clone a Repository
2.  Format Terraform files      11. Push Changes
3.  Add All + Initial Commit    12. Pull Changes
4.  Check Status                13. Fetch (no merge)
5.  Add File + Commit           14. Pull Requests (GitHub CLI)
6.  Add Folder + Commit         15. Manage Remotes (sub-menu)
7.  Add All + Commit
8.  View Changes / Diff         --- History ---
9.  Discard Changes             16. View Commit Log
                                17. Stash Changes
--- Branch Operations ---       18. Apply Stash
19. Branch Management (sub-menu)
20. Merge a Branch              --- Advanced ---
21. Rebase Current Branch       22. Cherry-Pick a Commit
                                23. Revert a Commit
                                24. Create a Version Tag
```

### What makes it educational

Every option shows this before asking for input:

```
╔══════════════════════════════════════════════════════════════╗
║  git clone                                                   ║
╚══════════════════════════════════════════════════════════════╝
  What it does : Downloads a remote repository to your machine.
  When to use  : Starting work on an existing project for the first time.
  Safe?        : Yes — nothing on the remote is changed.

  Hints:
  • URL format   : https://github.com/user/repo.git
  • After clone  : cd into the folder, then run npm install / pip install
  • Private repo : make sure you are authenticated (gh auth login or SSH key)
```

And after every action, prints the exact commands that ran:

```
================================================================
  Commands used:
  > git clone https://github.com/xbiz-cmyk/aiolympus.git my-project
  > cd my-project
================================================================
```

### Requirements

| Tool | Required | Install |
|------|----------|---------|
| PowerShell 5.1+ | ✅ Yes | Built into Windows; `brew install powershell` on Mac |
| Git | ✅ Yes | [git-scm.com](https://git-scm.com) |
| GitHub CLI (`gh`) | Optional | [cli.github.com](https://cli.github.com) — for Pull Request features |
| Terraform | Optional | [terraform.io](https://www.terraform.io) — for option 2 only |

### Pull Request workflow (option 14)

Requires `gh` CLI and `gh auth login` first:

```
feature/my-branch
      ↓  option 14a: gh pr create
   GitHub PR (open for review)
      ↓  option 14d: gh pr merge
   main branch ✅
```

---

## 🧠 Built By

Kossi Eglo — [kossi.eglo@stackit.cloud](mailto:kossi.eglo@stackit.cloud)
AI-assisted development by Rox (OpenClaw agent).

---

## 📄 License

MIT — use freely, contribute back.
