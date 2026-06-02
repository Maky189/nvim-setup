# nvim-setup

Portable LazyVim configuration with an installer that bootstraps Neovim on any
Linux distribution to match this exact setup.

## What's inside

- `nvim/` — the full `~/.config/nvim` LazyVim configuration (plugins, keymaps,
  options, autocmds, `lazy-lock.json` for reproducible plugin versions).
- `install.sh` — detects the distro's package manager (apt / dnf / pacman /
  zypper / apk), installs Neovim and the build/runtime dependencies LazyVim
  needs, backs up any existing config, copies this one into place, and runs a
  headless `Lazy restore` + `Lazy sync` so plugins are pinned to the same
  versions as on the source machine.

## Usage on a new machine

```bash
git clone <this-repo-url> ~/nvim-setup
cd ~/nvim-setup
chmod +x install.sh
./install.sh
nvim
```

## Notes

- The installer backs up any existing `~/.config/nvim`, `~/.local/share/nvim`,
  `~/.local/state/nvim`, and `~/.cache/nvim` with a timestamp suffix — nothing
  is destroyed.
- LazyVim needs Neovim **0.9+** (0.10 recommended). If your distro ships an
  older version, grab the AppImage from
  <https://github.com/neovim/neovim/releases>.
- Enabled LazyVim extras: `ai.avante`, `ai.copilot`.
- After install, open `nvim` once and let Mason finish installing LSPs /
  formatters / DAPs (`:Mason` to inspect).

## Updating the repo from the source machine

When you change your Neovim config on the source machine, refresh this repo:

```bash
rm -rf ~/Documents/nvim-setup/nvim
cp -r ~/.config/nvim ~/Documents/nvim-setup/nvim
rm -rf ~/Documents/nvim-setup/nvim/.git
cd ~/Documents/nvim-setup && git add -A && git commit -m "sync nvim config"
```
