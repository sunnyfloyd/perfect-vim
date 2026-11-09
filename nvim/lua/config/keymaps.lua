-- Keymaps added on top of LazyVim's. Press <Space> and wait to see all of them,
-- or press F1 for the cheat sheet.
local map = vim.keymap.set

local function cheatsheet()
  require("config.cheatsheet").toggle()
end
map({ "n", "i" }, "<F1>", cheatsheet, { desc = "Cheat Sheet" })
map("n", "<leader>h", cheatsheet, { desc = "Cheat Sheet" })
vim.api.nvim_create_user_command("Cheatsheet", cheatsheet, { desc = "Open the Perfect Vim cheat sheet" })
