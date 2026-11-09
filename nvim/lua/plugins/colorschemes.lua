-- Themes. Pick one with <leader>uC (live preview); your choice is remembered.
-- tokyonight and catppuccin come with LazyVim; the rest load only when selected.

local state_file = vim.fn.stdpath("state") .. "/pvim-colorscheme"

-- Remember the last colorscheme applied (picker, :colorscheme, ...)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("pvim_colorscheme", { clear = true }),
  callback = function(ev)
    local f = io.open(state_file, "w")
    if f then
      f:write(ev.match)
      f:close()
    end
  end,
})

local function saved_colorscheme()
  local f = io.open(state_file, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  return name
end

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local name = saved_colorscheme()
        if not (name and pcall(vim.cmd.colorscheme, name)) then
          vim.cmd.colorscheme("tokyonight")
        end
      end,
    },
  },

  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "navarasu/onedark.nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "projekt0n/github-nvim-theme", name = "github-theme", lazy = true },
  { "sainnhe/everforest", lazy = true },
}
