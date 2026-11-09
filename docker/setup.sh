#!/usr/bin/env bash
# Installs (or with --update, updates) everything stored in the persistent home volume:
#   Claude Code, Neovim plugins, language servers / linters / formatters / debuggers,
#   and Treesitter parsers.
# Safe to run any time:  pvim-setup  |  pvim-setup --update
set -uo pipefail

mode=install
[[ "${1:-}" == "--update" ]] && mode=update
failed=()
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

step "Claude Code"
if command -v claude >/dev/null 2>&1; then
  if [[ $mode == update ]]; then claude update || failed+=("claude update"); fi
  claude --version
else
  curl -fsSL https://claude.ai/install.sh | bash || failed+=("Claude Code install")
fi

step "Neovim plugins"
if [[ $mode == update ]]; then
  # Newest versions; rewrites lazy-lock.json in your config folder
  nvim --headless "+Lazy! sync" +qa || failed+=("plugin update")
else
  # Exact versions from lazy-lock.json (known-good set)
  nvim --headless "+Lazy! restore" +qa || failed+=("plugin install")
fi

step "Language servers, linters, formatters, debuggers, Treesitter parsers"
warm=$(mktemp -d)
touch "$warm/warmup.py"
PVIM_MODE=$mode nvim --headless "$warm/warmup.py" -c "luafile /etc/pvim/warmup.lua" || failed+=("language tools")
rm -rf "$warm"

if ((${#failed[@]})); then
  printf '\n\033[1;31mSome steps failed: %s\033[0m\nRe-run with: pvim-setup\n' "${failed[*]}"
  exit 1
fi

mkdir -p "$HOME/.local/state/pvim"
date -Iseconds > "$HOME/.local/state/pvim/setup-done"
printf '\n\033[1;32mAll set.\033[0m\n'
