-- Autocmds added on top of LazyVim's (which already reload files on focus).
local augroup = vim.api.nvim_create_augroup("pvim", { clear = true })

-- Files edited outside Neovim (Claude Code in another terminal, a Windows app) are
-- reloaded within ~2 seconds. Buffers with unsaved changes are never overwritten:
-- Neovim asks what to do instead.
local timer = vim.uv.new_timer()
if timer then
  timer:start(2000, 2000, vim.schedule_wrap(function()
    if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
      pcall(vim.cmd, "silent! checktime")
    end
  end))
end

-- Quitting with a terminal open (the Claude Code panel, the Ctrl+/ shell) froze Neovim:
-- Snacks closes terminal windows when Neovim exits, and closing a terminal window while
-- exiting hangs. Skip that step (this runs first); Neovim stops the programs itself.
vim.api.nvim_create_autocmd("ExitPre", {
  group = augroup,
  callback = function()
    for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "ExitPre" })) do
      if (au.group_name or ""):match("^snacks_win") then
        pcall(vim.api.nvim_del_autocmd, au.id)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = augroup,
  callback = function(ev)
    vim.notify("Reloaded " .. vim.fn.fnamemodify(ev.file, ":~:."), vim.log.levels.INFO, { title = "Changed on disk" })
  end,
})
