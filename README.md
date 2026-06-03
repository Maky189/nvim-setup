# nvim-setup

This is my personal Neovim setup — a portable [LazyVim](https://www.lazyvim.org/)
configuration with an installer that bootstraps a fresh machine to match exactly
how I work. I keep it here so I can clone it onto any Linux box and be productive
in a couple of minutes.

## How I like to code

I want my editor to stay out of my way. A few principles drive the whole config:

- **No nagging.** I turned off all diagnostic visuals — no red underlines, no
  inline error text, no sign-column markers. If I reference a function or import
  that doesn't exist yet, the name still gets colored normally; the editor
  doesn't paint it red. I rely on **treesitter** for highlighting, so the only
  time something loses its color is a genuine syntax error.
- **I format on my own terms.** Auto-format on save is off. I format manually
  when I actually want to (`<leader>cf`). The editor never silently rewrites my
  style. My Lua style is 2-space indent, 120-column width (see `stylua.toml`).
- **A quiet startup.** I suppress the notification spam that normally pops up
  when Neovim launches, so opening `nvim` is clean. Anything important is still
  reachable via `:messages` or `:Lazy`.
- **Claude is my pair.** I use Claude as my in-editor coding agent, running on my
  Claude subscription (not the paid API). Copilot is installed but stays dormant
  unless I deliberately switch it on.
- **My theme follows me.** Whatever colorscheme I pick is remembered across
  sessions automatically.


## How it's configured

Built on LazyVim, with these deliberate customizations of mine:

| Area | What I did |
|------|------------|
| **Diagnostics** | Underlines, virtual text and signs all disabled — syntax highlighting only (`lua/plugins/lsp.lua` + an `LspAttach` autocmd). LSP itself stays on, so go-to-definition / hover / rename still work. |
| **Formatting** | `vim.g.autoformat = false` — no auto-fix on save. |
| **AI agent** | Claude via [`coder/claudecode.nvim`](https://github.com/coder/claudecode.nvim), driving the `claude` CLI on my subscription (`lua/plugins/claudecode.lua`). |
| **avante** | Disabled — it uses the paid API. Easy to flip back on in `lua/plugins/avante.lua` if I ever want it. |
| **Copilot** | Installed but off by default (no auto-suggestions). Toggle on with `<leader>cp`. |
| **Theme persistence** | Active colorscheme is saved on change and reloaded on startup (`lua/config/autocmds.lua` + `lua/plugins/colorscheme.lua`). Default is `tokyonight-moon`. |
| **Clean startup** | Startup notifications swallowed until the UI is ready (`lua/config/options.lua`). |
| **Debugging** | `nvim-dap` configured for C/C++ via `cppdbg` / `OpenDebugAD7` (`lua/plugins/dap.lua`). |
| **Dashboard** | Custom snacks dashboard header (`lua/plugins/snacks.lua`). |
| **Discord** | Rich presence via `neocord` (`lua/plugins/presence.lua`). |
| **Font** | JetBrainsMono Nerd Font, installed and applied by `install.sh`. |

## Extensions I use

The full, version-pinned list lives in `nvim/lazy-lock.json`. The ones I care
about most:

**AI**
- `coder/claudecode.nvim` — Claude as my coding agent (my subscription)
- `zbirenbaum/copilot.lua` (+ `blink-copilot`) — Copilot, kept dormant
- `yetone/avante.nvim` — present but disabled

**Editing & navigation**
- `snacks.nvim` — dashboard, picker, explorer, terminal, and more
- `telescope.nvim` — fuzzy finder
- `nvim-treesitter` (+ textobjects, autotag, ts-comments) — highlighting & syntax
- `flash.nvim` — fast on-screen jumps
- `mini.ai` / `mini.pairs` / `mini.icons` — text objects, auto-pairs, icons
- `which-key.nvim` — keymap discovery

**LSP / tooling**
- `nvim-lspconfig` + `mason.nvim` (+ `mason-lspconfig`) — language servers
- `conform.nvim` / `nvim-lint` / `none-ls.nvim` — formatting & linting (manual)
- `lazydev.nvim` — Lua/Neovim dev
- `nvim-dap` — debugging (C/C++)

**UI / quality of life**
- `tokyonight.nvim` + `catppuccin` — themes
- `lualine.nvim`, `bufferline.nvim`, `noice.nvim`
- `gitsigns.nvim`, `todo-comments.nvim`, `trouble.nvim`, `grug-far.nvim`
- `persistence.nvim` — session restore
- `neocord` — Discord presence

## My keyboard shortcuts

Leader key is **Space**.

### Claude / AI (`<leader>a`)
| Key | Action |
|-----|--------|
| `<leader>ac` | Toggle the Claude sidebar |
| `<leader>af` | Focus Claude |
| `<leader>ar` | Resume my last Claude session |
| `<leader>aC` | Continue Claude |
| `<leader>am` | Pick the Claude model |
| `<leader>ab` | Add the current buffer to Claude's context |
| `<leader>as` | Send my visual selection to Claude (or add a file from the explorer) |
| `<leader>aa` | Accept a diff Claude proposes |
| `<leader>ad` | Deny a diff Claude proposes |

### Copilot
| Key | Action |
|-----|--------|
| `<leader>cp` | Toggle Copilot inline suggestions on/off |
| `<M-l>` | Accept suggestion (when enabled) |
| `<M-]>` / `<M-[>` | Next / previous suggestion (when enabled) |

> First time using Claude: run `claude`, then `/login` and pick my account.
> First time using Copilot: `:Copilot auth`.

### Handy LazyVim defaults I rely on
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>/` | Grep in project |
| `<leader>e` | Toggle file explorer |
| `<leader>uC` | Pick a colorscheme (now persists!) |
| `<leader>cf` | Format buffer (manual) |
| `<leader>ca` | Code action |
| `<leader>gg` | Open Lazygit |
| `<leader>bd` | Close buffer |
| `s` | Flash jump |
| `gd` / `K` | Go to definition / hover docs |

## Usage on a new machine

```bash
git clone <this-repo-url> ~/nvim-setup
cd ~/nvim-setup
chmod +x install.sh
./install.sh
nvim
```

The installer detects the distro's package manager (apt / dnf / pacman / zypper /
apk), installs Neovim plus the build/runtime dependencies LazyVim needs, installs
and applies JetBrainsMono Nerd Font, backs up any existing config, copies this
one into place, and runs a headless `Lazy restore` + `Lazy sync` so plugins are
pinned to the same versions as on my source machine.

To use Claude afterwards, I make sure the Claude Code CLI is installed
(`npm install -g @anthropic-ai/claude-code`), then log in once with `claude` →
`/login`.

## Notes

- The installer backs up any existing `~/.config/nvim`, `~/.local/share/nvim`,
  `~/.local/state/nvim`, and `~/.cache/nvim` with a timestamp suffix — nothing
  is destroyed.
- LazyVim needs Neovim **0.9+** (0.10 recommended). If a distro ships an older
  version, I grab the AppImage from
  <https://github.com/neovim/neovim/releases>.
- Enabled LazyVim extras: `ai.avante` (disabled in config), `ai.copilot`.
- After install, I open `nvim` once and let Mason finish installing LSPs /
  formatters / DAPs (`:Mason` to inspect).

## Updating the repo from my source machine

When I change my Neovim config locally, I refresh this repo:

```bash
rm -rf ~/Documents/nvim-setup/nvim
cp -r ~/.config/nvim ~/Documents/nvim-setup/nvim
rm -rf ~/Documents/nvim-setup/nvim/.git
cd ~/Documents/nvim-setup && git add -A && git commit -m "sync nvim config"
```
