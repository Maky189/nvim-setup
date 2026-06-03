-- Sidebar AI coding agent = Claude (avante.nvim).
-- Requires an Anthropic API key exported in your shell:  export ANTHROPIC_API_KEY="sk-ant-..."
-- Open the sidebar with <leader>aa (ask) — see avante's <leader>a* keymaps.
return {
  "yetone/avante.nvim",
  opts = {
    provider = "claude",
    claude = {
      model = "claude-sonnet-4-6",
    },
  },
}
