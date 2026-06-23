#!/usr/bin/env pwsh
# Installs Neovim + this LazyVim config on Windows.
# Usage (from PowerShell):
#     .\install.ps1
# If you hit an execution-policy error, run:
#     powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NvimSrc   = Join-Path $ScriptDir 'nvim'
$NvimDst   = Join-Path $env:LOCALAPPDATA 'nvim'         # %LOCALAPPDATA%\nvim
$NvimData  = Join-Path $env:LOCALAPPDATA 'nvim-data'    # plugins / lazy-lock state

function Info($m) { Write-Host "[*] $m" -ForegroundColor Blue }
function Ok($m)   { Write-Host "[+] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Err($m)  { Write-Host "[x] $m" -ForegroundColor Red }

function Have($cmd) { $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

# ---------- detect a package manager ----------
function Get-Pm {
    if (Have winget) { return 'winget' }
    if (Have scoop)  { return 'scoop' }
    if (Have choco)  { return 'choco' }
    return 'unknown'
}

$Pm = Get-Pm
Info "Detected package manager: $Pm"

# ---------- install dependencies ----------
# neovim, git, curl, ripgrep, fd, node (for LSPs), python, lua/luarocks (avante).
function Install-Pkg($winget, $scoop, $choco) {
    switch ($Pm) {
        'winget' {
            if ($null -ne $winget) {
                winget install --accept-source-agreements --accept-package-agreements `
                    --silent --disable-interactivity -e --id $winget
            }
        }
        'scoop'  { if ($null -ne $scoop) { scoop install $scoop } }
        'choco'  { if ($null -ne $choco) { choco install -y $choco } }
    }
}

function Install-Deps {
    switch ($Pm) {
        'winget' {
            Install-Pkg 'Neovim.Neovim'      $null $null
            Install-Pkg 'Git.Git'            $null $null
            Install-Pkg 'BurntSushi.ripgrep.MSVC' $null $null
            Install-Pkg 'sharkdp.fd'         $null $null
            Install-Pkg 'OpenJS.NodeJS.LTS'  $null $null
            Install-Pkg 'Python.Python.3.12' $null $null
            Install-Pkg 'GnuWin32.Make'      $null $null
        }
        'scoop' {
            scoop install neovim git ripgrep fd nodejs-lts python make
        }
        'choco' {
            choco install -y neovim git ripgrep fd nodejs-lts python make
        }
        default {
            Warn "No supported package manager (winget/scoop/choco) found."
            Warn "Install these manually, then re-run: neovim git ripgrep fd nodejs python make"
        }
    }
}

Info "Installing dependencies..."
Install-Deps
Ok "Dependencies installed."

# Make freshly installed tools available to this session without a new shell.
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path    = "$machinePath;$userPath"

# ---------- check neovim ----------
if (Have nvim) {
    $verLine = (& nvim --version | Select-Object -First 1)
    Info "Neovim version: $verLine"
    if ($verLine -match 'v(\d+)\.(\d+)') {
        $maj = [int]$Matches[1]; $min = [int]$Matches[2]
        if ($maj -eq 0 -and $min -lt 9) {
            Warn "Neovim < 0.9 - LazyVim requires 0.9+. Update from https://github.com/neovim/neovim/releases"
        }
    }
} else {
    Err "Neovim not found on PATH after install. Open a new terminal and re-run, or install it manually."
    exit 1
}

# ---------- back up existing config / data ----------
function Backup($p) {
    if (Test-Path -LiteralPath $p) {
        $b = "$p.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Warn "Backing up $p -> $b"
        Move-Item -LiteralPath $p -Destination $b
    }
}

Info "Backing up any existing Neovim config / data..."
Backup $NvimDst
Backup $NvimData

# ---------- deploy config ----------
Info "Copying config to $NvimDst"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $NvimDst) | Out-Null
Copy-Item -Recurse -Force -LiteralPath $NvimSrc -Destination $NvimDst
Ok "Config copied."

# ---------- install nerd font (current user) ----------
function Install-NerdFont {
    $fontName = 'JetBrainsMono Nerd Font'
    $installed = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter '*JetBrainsMono*NerdFont*.ttf' -ErrorAction SilentlyContinue
    if ($installed) {
        Ok "$fontName already installed - skipping."
        return
    }

    Info "Downloading $fontName..."
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "JetBrainsMonoNF"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $zip = Join-Path $tmp 'JetBrainsMono.zip'
    $url = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip'
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $tmp -Force

    # Per-user font install (no admin required): copy to local Fonts and register.
    $userFontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force -Path $userFontDir | Out-Null
    $regKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

    Get-ChildItem -Path $tmp -Filter '*.ttf' | ForEach-Object {
        $dest = Join-Path $userFontDir $_.Name
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
        $regName = ($_.BaseName -replace '-', ' ') + ' (TrueType)'
        New-ItemProperty -Path $regKey -Name $regName -Value $dest -PropertyType String -Force | Out-Null
    }
    Remove-Item -Recurse -Force $tmp
    Ok "$fontName installed for the current user."
    Warn "Set your terminal font to 'JetBrainsMono Nerd Font Mono' (restart the terminal to see it)."
}

Info "Installing NerdFont..."
try { Install-NerdFont } catch { Warn "Nerd Font install failed: $($_.Exception.Message)" }

# ---------- headless sync of plugins ----------
Info "Running headless LazyVim sync (this may take a few minutes)..."
try { & nvim --headless '+Lazy! restore' +qa } catch { Warn "Lazy restore had a non-zero exit - continuing." }
try { & nvim --headless '+Lazy! sync'    +qa } catch { Warn "Lazy sync had a non-zero exit - continuing." }
try { & nvim --headless '+MasonUpdate'   +qa } catch { }

Ok "Done! Launch with:  nvim"

# ---------- post-install notes ----------
Write-Host ''
Info "Config notes:"
Info "  - AI agent: Claude Code (uses your Claude subscription, not the API)."
if (-not (Have claude)) {
    Warn "      The 'claude' CLI was not found on PATH. Install it, e.g.:"
    Warn "        npm install -g @anthropic-ai/claude-code"
}
Info "      Log in once:  run 'claude', then /login and pick your account."
Info "      In nvim, toggle the Claude sidebar with  <leader>ac"
Info "  - avante (Claude via paid API) is disabled. Re-enable in"
Info "      lua/plugins/avante.lua (needs ANTHROPIC_API_KEY) if you prefer the API."
Info "  - Copilot is installed but OFF. Enable it anytime with  <leader>cp"
Info "      (first run only:  :Copilot auth)"
Info "  - Themes persist automatically - pick one with <leader>uC and it's remembered."
Info "  - Diagnostics (underlines/linters) are disabled; only syntax highlighting shows."
