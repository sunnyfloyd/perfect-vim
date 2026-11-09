-- Reviewing changes (yours or an AI agent's). LazyVim already has lazygit
-- (<leader>gg) and gitsigns (<leader>gh... for hunks). Diffview adds a side-by-side
-- review of every changed file.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      {
        "<leader>gv",
        function()
          if next(require("diffview.lib").views) == nil then
            vim.cmd("DiffviewOpen")
          else
            vim.cmd("DiffviewClose")
          end
        end,
        desc = "Review changes (Diffview toggle)",
      },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (Diffview)" },
    },
    opts = {
      enhanced_diff_hl = true,
    },
  },
}
