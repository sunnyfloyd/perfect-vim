-- Debugging. The `dap.core` extra provides everything under <leader>d; these add
-- VS Code style function keys. Python uses debugpy, JS/TS uses js-debug-adapter.
-- Note: Windows Terminal uses F11 for full screen; use <leader>di (step into) instead,
-- or remove F11 from Windows Terminal's actions.
local function dap(fn)
  return function()
    require("dap")[fn]()
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", dap("continue"), desc = "Debug: Start / Continue" },
      { "<S-F5>", dap("terminate"), desc = "Debug: Stop" },
      { "<F17>", dap("terminate"), desc = "Debug: Stop" }, -- Shift+F5 in some terminals
      { "<F9>", dap("toggle_breakpoint"), desc = "Debug: Toggle Breakpoint" },
      { "<F10>", dap("step_over"), desc = "Debug: Step Over" },
      { "<F11>", dap("step_into"), desc = "Debug: Step Into" },
      { "<S-F11>", dap("step_out"), desc = "Debug: Step Out" },
      { "<F23>", dap("step_out"), desc = "Debug: Step Out" }, -- Shift+F11 in some terminals
    },
  },
}
