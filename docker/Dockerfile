# Perfect Vim: Neovim (LazyVim) + dev tooling + Claude Code, ready to edit Windows folders.
#
# The image holds only system tools. Everything that changes often (Neovim plugins,
# language servers, Claude Code, your logins) lives in the "perfect-vim-home" volume,
# so it survives container restarts and image rebuilds.

FROM node:lts-trixie-slim

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    COLORTERM=truecolor \
    EDITOR=nvim \
    VISUAL=nvim

# --- System packages -------------------------------------------------------------
# build-essential: Treesitter compiles parsers with a C compiler
# python3-venv/pip + node/npm: Mason installs language servers with them
# libicu76: needed by .NET based tools such as marksman (Markdown language server)
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl wget ca-certificates gnupg openssh-client \
      unzip zip xz-utils gzip bzip2 tar \
      build-essential pkg-config libicu76 \
      ripgrep fd-find jq less file procps sudo bash-completion \
      python3 python3-venv python3-pip python3-dev \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# --- uv (fast Python package/venv manager) ---------------------------------------
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# --- tsx: runs TypeScript files directly; the debugger uses it for .ts files -------
RUN npm install -g tsx && npm cache clean --force

# --- Latest Neovim, lazygit, fzf, tree-sitter CLI, GitHub CLI ---------------------
# Rebuild with `pvim -Update` to pick up new releases.
RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$arch" in \
      amd64) nv=x86_64; lg=x86_64; fz=amd64; ts=x64;   gh=amd64 ;; \
      arm64) nv=arm64;  lg=arm64;  fz=arm64; ts=arm64; gh=arm64 ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    latest() { curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/v##'; }; \
    gh_dl="https://github.com"; \
    curl -fsSL "$gh_dl/neovim/neovim/releases/download/stable/nvim-linux-$nv.tar.gz" | tar -xz -C /opt; \
    ln -s "/opt/nvim-linux-$nv/bin/nvim" /usr/local/bin/nvim; \
    v=$(latest jesseduffield/lazygit); \
    curl -fsSL "$gh_dl/jesseduffield/lazygit/releases/download/v$v/lazygit_${v}_linux_${lg}.tar.gz" | tar -xz -C /usr/local/bin lazygit; \
    v=$(latest junegunn/fzf); \
    curl -fsSL "$gh_dl/junegunn/fzf/releases/download/v$v/fzf-$v-linux_$fz.tar.gz" | tar -xz -C /usr/local/bin fzf; \
    curl -fsSL "$gh_dl/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$ts.gz" | gunzip > /usr/local/bin/tree-sitter; \
    chmod +x /usr/local/bin/tree-sitter; \
    v=$(latest cli/cli); \
    curl -fsSL "$gh_dl/cli/cli/releases/download/v$v/gh_${v}_linux_${gh}.tar.gz" | tar -xz -C /tmp; \
    mv "/tmp/gh_${v}_linux_${gh}/bin/gh" /usr/local/bin/gh; rm -rf /tmp/gh_*; \
    nvim --version | head -1; lazygit --version; fzf --version; tree-sitter --version; gh --version | head -1

# --- User "dev" (uid 1000), passwordless sudo for ad-hoc installs ----------------
# The node base image ships user "node" with uid 1000; rename it.
RUN usermod -l dev -d /home/dev -m node \
    && groupmod -n dev node \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && printf '# Personal bash settings (kept in the perfect-vim-home volume).\n# Perfect Vim defaults live in /etc/pvim/bashrc.sh\n' > /home/dev/.bashrc \
    && chown dev:dev /home/dev/.bashrc \
    && mkdir -p /workspace && chown dev:dev /workspace

# --- Git defaults for folders shared with Windows ---------------------------------
# safe.directory: mounted files are owned by root, git would refuse them otherwise
# fileMode=false: Windows mounts report every file as executable
RUN git config --system safe.directory '*' \
    && git config --system core.fileMode false \
    && git config --system init.defaultBranch main

COPY bashrc.sh /etc/pvim/bashrc.sh
COPY entrypoint.sh /usr/local/bin/pvim-entrypoint
COPY setup.sh /usr/local/bin/pvim-setup
COPY warmup.lua /etc/pvim/warmup.lua
RUN chmod +x /usr/local/bin/pvim-entrypoint /usr/local/bin/pvim-setup \
    && echo '. /etc/pvim/bashrc.sh' >> /etc/bash.bashrc

USER dev
ENV PATH=/home/dev/.local/bin:$PATH
WORKDIR /workspace

ENTRYPOINT ["pvim-entrypoint"]
CMD ["nvim"]
