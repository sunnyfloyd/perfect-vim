-- Language support beyond the LazyVim extras in lazyvim.json
-- (Python, TypeScript/JavaScript, Markdown, JSON, YAML, TOML, Docker, Git).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Extra language servers: Bash, HTML, CSS
        bashls = {},
        html = {},
        cssls = {},
        -- Folders mounted from Windows show every file as executable, which makes
        -- Ruff report "executable file without shebang" everywhere. Ignore those two.
        ruff = {
          init_options = { settings = { lint = { ignore = { "EXE001", "EXE002" } } } },
        },
      },
    },
  },

  -- Tools installed by Mason (:Mason to browse, install or update more)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "debugpy", -- Python debugger
        "shellcheck", -- shell script linter (used by bashls)
      },
    },
  },

  -- Syntax highlighting parsers (:TSInstall <language> to add more)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "css", "scss", "sql", "ini", "csv", "make" },
    },
  },

  -- Markdown preview in a browser can't open from inside Docker. Markdown is rendered
  -- right in the editor instead (render-markdown.nvim, toggle with <leader>um).
  { "iamcco/markdown-preview.nvim", enabled = false },
}
