-- Claude Code inside Neovim (the `ai.claudecode` extra adds the <leader>a keys).
-- Claude sees your open file and selection, and its edits open as diffs you
-- accept (<leader>aa) or reject (<leader>ad).
return {
  {
    "coder/claudecode.nvim",
    -- Load on these commands too, so :ClaudeCode works from the dashboard
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSend",
      "ClaudeCodeAdd",
      "ClaudeCodeSelectModel",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeStatus",
    },
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.40,
      },
    },
    keys = {
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    },
  },
}
