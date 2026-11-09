-- Headless warm-up used by `pvim-setup`. Installs (PVIM_MODE=update: also updates)
-- what LazyVim would otherwise install in the background the first time you open a
-- file: Treesitter parsers and Mason packages (language servers, linters, formatters,
-- debug adapters). Exits 0 when everything is installed, 1 otherwise.
local update = vim.env.PVIM_MODE == "update"
local timeout = 20 * 60 * 1000
local failed = {} ---@type string[]

local function say(msg)
  io.stdout:write(msg .. "\n")
  io.stdout:flush()
end

-- Load the plugins that declare what to install (some are lazy-loaded on keys)
require("lazy").load({ plugins = { "nvim-lspconfig", "mason.nvim", "mason-lspconfig.nvim", "nvim-treesitter" } })
pcall(require("lazy").load, { plugins = { "nvim-dap" } })

-- Treesitter parsers ---------------------------------------------------------------
local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
say(("Treesitter: %d parsers"):format(#parsers))
local ok, err = pcall(function()
  local ts = require("nvim-treesitter")
  ts.install(parsers, { summary = true }):wait(timeout)
  if update then
    ts.update(nil, { summary = true }):wait(timeout)
  end
end)
if not ok then
  failed[#failed + 1] = "treesitter: " .. tostring(err)
end
-- LazyVim starts its own install at startup; parsers it is still busy with were
-- skipped above, so wait for them too.
local function missing_parsers()
  local have = require("nvim-treesitter").get_installed()
  return vim.tbl_filter(function(lang)
    return not vim.tbl_contains(have, lang)
  end, parsers)
end
vim.wait(timeout, function()
  return #missing_parsers() == 0
end, 500)
for _, lang in ipairs(missing_parsers()) do
  failed[#failed + 1] = "treesitter parser: " .. lang
end

-- Mason packages -------------------------------------------------------------------
local mr = require("mason-registry")
local refreshed = false
mr.refresh(function()
  refreshed = true
end)
vim.wait(120000, function()
  return refreshed
end, 200)

local wanted = {} ---@type table<string, boolean>
for _, name in ipairs(LazyVim.opts("mason.nvim").ensure_installed or {}) do
  wanted[name] = true
end
local to_package = require("mason-lspconfig").get_mappings().lspconfig_to_package
for server, sopts in pairs(LazyVim.opts("nvim-lspconfig").servers or {}) do
  local enabled = sopts ~= false and not (type(sopts) == "table" and (sopts.enabled == false or sopts.mason == false))
  if server ~= "*" and enabled and to_package[server] then
    wanted[to_package[server]] = true
  end
end
local names = vim.tbl_keys(wanted)
table.sort(names)
say("Mason: " .. table.concat(names, ", "))

for _, name in ipairs(names) do
  local found, pkg = pcall(mr.get_package, name)
  if not found then
    failed[#failed + 1] = "mason: unknown package " .. name
  elseif not pkg:is_installing() then
    local outdated = false
    if update and pkg:is_installed() then
      local v_ok, latest = pcall(pkg.get_latest_version, pkg)
      outdated = v_ok and latest ~= pkg:get_installed_version()
    end
    if not pkg:is_installed() or outdated then
      say("  installing " .. name)
      pcall(pkg.install, pkg)
    end
  end
end

vim.wait(timeout, function()
  for _, name in ipairs(names) do
    local found, pkg = pcall(mr.get_package, name)
    if found and pkg:is_installing() then
      return false
    end
  end
  return true
end, 500)

for _, name in ipairs(names) do
  if not mr.is_installed(name) then
    failed[#failed + 1] = "mason: " .. name
  end
end

-- Result -----------------------------------------------------------------------------
if #failed > 0 then
  say("Not installed:\n  " .. table.concat(failed, "\n  "))
  vim.cmd("cquit! 1")
else
  say(("OK: %d parsers, %d Mason packages"):format(#parsers, #names))
  vim.cmd("qall!")
end
