#!/usr/bin/env bash
# Runs every time a Perfect Vim container starts, then hands over to the
# requested command (nvim by default).
set -u

# SSH keys (only with `pvim -Ssh`): Windows keys are mounted read-only at /run/host-ssh.
# ssh refuses keys with loose permissions, so copy them into the in-memory ~/.ssh.
if [[ -d /run/host-ssh ]]; then
  sudo chown dev:dev "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  cp -r /run/host-ssh/. "$HOME/.ssh/" 2>/dev/null
  find "$HOME/.ssh" -type f -exec chmod 600 {} +
fi

# First start (or after `pvim -Reset`): install plugins, language tools and Claude Code.
if [[ ! -f "$HOME/.local/state/pvim/setup-done" ]]; then
  echo "First start: installing editor plugins and language tools (one time, a few minutes)..."
  pvim-setup
fi

exec "$@"
