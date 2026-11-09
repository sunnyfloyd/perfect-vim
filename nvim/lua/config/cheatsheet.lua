-- Floating window with cheatsheet.md (F1, <leader>h, :Cheatsheet).
local M = {}

local win ---@type snacks.win?

function M.toggle()
  if win and win:valid() then
    win:close()
    win = nil
    return
  end
  win = Snacks.win({
    file = vim.fn.stdpath("config") .. "/cheatsheet.md",
    width = 0.85,
    height = 0.9,
    border = "rounded",
    title = "  Cheat Sheet   q / F1 close · / search · <C-d> <C-u> scroll ",
    title_pos = "center",
    backdrop = 60,
    bo = { modifiable = false },
    wo = {
      wrap = true,
      linebreak = true,
      spell = false,
      conceallevel = 2,
      number = false,
      relativenumber = false,
      signcolumn = "no",
      cursorline = true,
    },
    keys = {
      q = "close",
      ["<F1>"] = "close",
      ["<Esc>"] = "close",
    },
  })
  -- It's a reference card, not a document being written: hide Markdown lint warnings
  vim.diagnostic.enable(false, { bufnr = win.buf })
end

return M
