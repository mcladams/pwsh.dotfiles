# Windows Dotfiles & PowerShell Automation

A modular, repeatable PowerShell configuration and installation repository for Windows 11.

## Layout

Clone this repository to your home directory:

```powershell
git clone https://github.com/mcladams/windows-config-dotfiles.git $HOME\.dotfiles
```

Key files:

- `$HOME\.dotfiles\setup.ps1` — **one‑off** bootstrap script (requires Administrator).
- `$HOME\.dotfiles\powershell\profile.pwsh7.ps1` — PowerShell 7 profile (repo).
- `$HOME\.dotfiles\powershell\profile.ps5.ps1` — PowerShell 5 profile (repo).
- `$HOME\.dotfiles\powershell\profile.ps1` — shared profile logic.
- `$HOME\.dotfiles\powershell\psreadline.ps1` — PSReadLine configuration (ListView + git predictor).
- `$HOME\.dotfiles\powershell\functions.ps1` — utility functions.

## Installation (one-off)

1. Open PowerShell **as Administrator**.
2. Run the bootstrap script:

```powershell
& $HOME\.dotfiles\setup.ps1
```

`setup.ps1` will:

- Ensure TLS 1.2 is enabled for the session.
- Install and configure Scoop (preferred) or fall back to winget.
- Install core tools (git, pwsh, oh-my-posh, notepad++).
- Install PowerShell modules (PSReadLine, CompletionPredictor).
- Write minimal profile stubs into the system/user profile locations that dot-source the repo scripts.

After `setup.ps1` completes, open a **new** PowerShell (pwsh) session.

## Notes & Safety

- `setup.ps1` is intentionally **one‑off** and requires Administrator privileges.
- Profiles in the OS locations are minimal stubs that only dot-source the repo files.
- All heavy provisioning is done by `setup.ps1` — your `$PROFILE` files remain fast and safe.
- If you want a custom oh‑my‑posh theme, add `kali.omp.json` to `powershell/` or edit `profile.ps1` to point to a different theme.

## Customization

- Toggle PSReadLine ListView vs InlineView by editing `powershell/psreadline.ps1` (one line).
- Change edit mode (Windows/Emacs/Vi) in `psreadline.ps1`.
- Add or remove Scoop packages in `setup.ps1` under the `$packages` array.

## Troubleshooting

- If PSReadLine suggestions are missing, ensure `CompletionPredictor` is installed:
  ```powershell
  Install-Module CompletionPredictor -Scope CurrentUser -Force
  ```
- If oh‑my‑posh theme does not appear, either add `kali.omp.json` to `powershell/` or change the fallback theme in `profile.ps1`.