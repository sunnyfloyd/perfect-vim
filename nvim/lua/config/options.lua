-- Options load before plugins. LazyVim's defaults (line numbers, relative numbers,
-- smart case search, persistent undo, ...) are listed at
-- https://www.lazyvim.org/configuration/general
local opt = vim.opt

opt.scrolloff = 8 -- keep 8 lines visible above/below the cursor
opt.autoread = true -- reload files changed on disk (an AI agent, a Windows app)
opt.spelllang = { "en" }
-- No swap files: closing the terminal kills the container, which would leave stale
-- swap files and an "ATTENTION" prompt next time. Undo history is still saved (:h undofile).
opt.swapfile = false

-- Prettier only formats on save in projects that have a Prettier config, so opening a
-- random Markdown/JSON/YAML file doesn't rewrite it. Toggle autoformat with <leader>uf.
vim.g.lazyvim_prettier_needs_config = true

-- Clipboard -------------------------------------------------------------------------
-- Yank (y) copies to the Windows clipboard through Windows Terminal (OSC 52).
-- Terminals can't send the clipboard back on request, so `p` pastes Neovim's last
-- yank. To paste from Windows, use Ctrl+V (or right-click) in Windows Terminal.
opt.clipboard = "unnamedplus"
local osc52 = require("vim.ui.clipboard.osc52")
local function paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end
vim.g.clipboard = {
  name = "OSC 52 (copy only)",
  copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
  paste = { ["+"] = paste, ["*"] = paste },
}

-- Python virtualenv -------------------------------------------------------------------
-- Use the project's Linux virtualenv automatically (for the language server, the
-- debugger, tests and the terminal). A venv created on Windows has Scripts\python.exe
-- instead of bin/python, can't run in Linux and is ignored. If your project already
-- has a Windows .venv, create a separate Linux one:  uv venv .venv-linux
for _, name in ipairs({ ".venv-linux", ".venv", "venv" }) do
  local dir = vim.fn.getcwd() .. "/" .. name
  if vim.uv.fs_stat(dir .. "/bin/python") then
    vim.env.VIRTUAL_ENV = dir
    vim.env.PATH = dir .. "/bin:" .. vim.env.PATH
    break
  end
end
