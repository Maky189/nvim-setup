-- Theme persistence: load the last colorscheme the user picked.
-- The choice is saved by the ColorScheme autocmd in lua/config/autocmds.lua.
-- If nothing has been saved yet, the LazyVim default is kept.
return {
  "LazyVim/LazyVim",
  opts = function(_, opts)
    local fd = io.open(vim.fn.stdpath("state") .. "/last_colorscheme", "r")
    if fd then
      local name = fd:read("*l")
      fd:close()
      if name and name ~= "" then
        opts.colorscheme = name
      end
    end
  end,
}
