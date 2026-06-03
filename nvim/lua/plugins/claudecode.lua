-- Claude as the in-editor coding agent, powered by the Claude Code CLI.
-- This uses your Claude SUBSCRIPTION (Pro/Max) — not the pay-per-token API —
-- because it drives the `claude` CLI, which authenticates to your account.
--
-- One-time setup:
--   1. Make sure the Claude Code CLI is installed and on PATH (`claude`).
--   2. Run `claude` in a terminal, then `/login` and pick your Claude account.
--
-- Then inside nvim:  <leader>ac  toggles the Claude sidebar.
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- Resolve the `claude` binary robustly: prefer PATH, fall back to the
    -- usual local install location (avoids "claude not found" if PATH is thin).
    terminal_cmd = (function()
      local p = vim.fn.exepath("claude")
      return p ~= "" and p or vim.fn.expand("~/.local/bin/claude")
    end)(),
  },
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file to Claude",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
    },
    -- Diff review (when Claude proposes an edit)
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
  },
}
