-- Start screen: adds "Cheat Sheet" and "Claude Code" to LazyVim's dashboard.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local keys = vim.tbl_get(opts, "dashboard", "preset", "keys")
      if not keys then
        return
      end
      table.insert(keys, 1, {
        icon = "󰋖 ",
        key = "h",
        desc = "Cheat Sheet (F1)",
        action = function()
          require("config.cheatsheet").toggle()
        end,
      })
      table.insert(keys, 2, { icon = "󰚩 ", key = "a", desc = "Claude Code", action = ":ClaudeCode" })
    end,
  },
}
