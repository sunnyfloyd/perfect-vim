# Perfect Vim

A complete Vim setup for programming with AI on Windows: Neovim with [LazyVim](https://www.lazyvim.org)
and [Claude Code](https://code.claude.com), running in Docker, editing your normal Windows folders.

```powershell
cd C:\code\my-app
pvim
```

That's it: the folder opens in Neovim, with language servers, debugger, git tools and Claude Code
ready to use. Press **F1** for the cheat sheet.

## What you get

| Feature                            | How to use it                                                                                                                                    |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Fuzzy file search                  | `Space Space`                                                                                                                                    |
| Search text in all files           | `Space /`                                                                                                                                        |
| File explorer                      | `Space e`                                                                                                                                        |
| Syntax highlighting (Treesitter)   | automatic, 38 languages preinstalled                                                                                                             |
| Themes with live preview           | `Space uC` (choice is remembered)                                                                                                                |
| Errors and warnings while you type | Python (pyright, ruff), TypeScript/JavaScript (vtsls, ESLint), Markdown (marksman, markdownlint), JSON, YAML, TOML, Docker, Bash, HTML, CSS, Lua |
| Format on save                     | ruff, Prettier (in projects with a Prettier config), stylua, shfmt                                                                               |
| Debugger                           | `F9` breakpoint, `F5` start, `F10` / `F11` step (Python and JS/TS)                                                                               |
| Tests                              | `Space tt` (pytest built in)                                                                                                                     |
| Git                                | `Space gg` lazygit, `Space gv` review changes, `]h` next change                                                                                  |
| Claude Code inside the editor      | `Space ac` (sees your file and selection, proposes diffs)                                                                                        |
| Cheat sheet                        | `F1`, or press `Space` and wait for the menu                                                                                                     |

## Install (once)

You need:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- [Windows Terminal](https://aka.ms/terminal) (recommended: it supports true colors, the mouse and copying to the Windows clipboard)

Then:

1. Put this folder somewhere permanent. The `pvim` command runs from here.
2. Double-click **`install.cmd`**, or run it from a terminal. It takes 5–10 minutes and:
   - builds the Docker image,
   - installs the editor plugins, language tools and Claude Code,
   - adds `pvim` to your PATH,
   - installs a Nerd Font for icons (skipped if you already have one),
   - adds a **Perfect Vim** profile to Windows Terminal (with that font).
3. Open a **new** terminal window and run `pvim` in any project folder.
4. First time only: press `Space` `a` `c` to open Claude Code and log in. If it shows a link,
   open the link in your Windows browser and paste the code back. The login is kept.

## Daily use

| Command                | What it does                                                            |
| ---------------------- | ----------------------------------------------------------------------- |
| `pvim`                 | Open the current folder                                                 |
| `pvim C:\code\app`     | Open a folder                                                           |
| `pvim .\src\main.py`   | Open a file (its project folder is mounted)                             |
| `pvim -Claude`         | Claude Code without the editor                                          |
| `pvim -Shell`          | A bash shell in the same environment                                    |
| `pvim -Port 3000,5173` | Also make dev servers reachable at `http://localhost:3000` from Windows |
| `pvim -Ssh`            | Use your Windows SSH keys inside (for `git push` over SSH)              |
| `pvim -Update`         | Newest Neovim, tools, plugins, language servers                         |
| `pvim -Setup`          | Reinstall plugins and tools if something is missing                     |
| `pvim -Reset`          | Start fresh: deletes plugins, logins and history (never your files)     |
| `pvim -DryRun`         | Show the `docker run` command instead of running it                     |
| `pvim -Help`           | All options                                                             |

You can run several `pvim` sessions at once, for different projects or the same one.

With `-Port`, the dev server inside must listen on all interfaces, not just localhost, for example
`npm run dev -- --host 0.0.0.0` (Vite), `next dev -H 0.0.0.0`, `flask run --host 0.0.0.0`,
`uvicorn app:app --host 0.0.0.0`.

## How it works with your Windows folders

```text
 Windows                                   Docker container (removed when you quit)
 ─────────────────────────────────         ─────────────────────────────────────────
 C:\code\my-app             ── live ──▶    /workspace/my-app       your project
 perfect-vim\nvim\          ── live ──▶    ~/.config/nvim          editor config
 Docker volume                             ~/                      plugins, language tools,
   "perfect-vim-home"       ─────────▶                             Claude login, history
```

- **Your project folder is mounted live.** Saving in Neovim changes the file in Windows right away,
  and changes made in Windows (VS Code, another AI tool, git) show up in Neovim within about
  2 seconds. Files you haven't modified reload on their own; for files with unsaved changes,
  Neovim asks what to do.
- If the folder is inside a git repository, the **whole repository** is mounted, so git, search and
  the language servers see the full project.
- The container only lives while Neovim runs. What must survive (plugins, language servers,
  Claude Code and its login, shell history, undo history, your theme) is kept in the
  `perfect-vim-home` Docker volume.
- Git inside uses your Windows name, email and line-ending setting (`core.autocrlf`), so
  `git status` agrees with Git for Windows.

### Good to know when Windows and Linux share a folder

- **Python virtualenvs** are per operating system. A `.venv` made on Windows can't run in Linux.
  Inside `pvim` (`Ctrl+/` opens a terminal), create a Linux one and install your dependencies:

  ```bash
  uv venv .venv            # or .venv-linux if the project already has a Windows .venv
  source .venv/bin/activate
  uv pip install -r requirements.txt
  ```

  From the next start on, Neovim uses it automatically for the language server, debugger and
  tests (`.venv-linux`, `.venv` and `venv` are detected). To switch right away: `Space cv`.

- **`node_modules`** can contain OS-specific binaries (esbuild, swc, …). Run `npm install` on the
  side where you run the code. If you run and test inside `pvim` (or let Claude do it), install there.
- **Speed:** editing is instant, but very file-heavy jobs (a big `npm install`) are slower on a
  Windows folder than on a native Linux disk.
- **Installing system packages:** `sudo apt install …` works but is gone after you quit. Add
  permanent ones to the `apt-get install` list in [docker/Dockerfile](docker/Dockerfile) and run `pvim -Build`.

## Working with Claude Code

1. `Space ac` opens Claude in a panel on the right. Claude knows which file you're in and what
   you selected (select lines, then `Space as` to send them).
2. When Claude wants to change a file, the change opens as a diff. `Space aa` accepts, `Space ad` rejects.
3. Review everything it did with `Space gv` (side-by-side diff of all changed files), jump between
   changes with `]h` / `[h`, undo a single change with `Space ghr`, then commit with `Space gg`.
4. `Ctrl+H` moves from the Claude panel back to your code; `Space ac` hides the panel.

The container keeps Claude away from the rest of your PC: it sees only the mounted project folder
and its own home volume. It can still use the network and change anything in the project folder,
so commit your work before letting it run long tasks.

Other ways to use it:

- `pvim -Claude` runs Claude Code on its own in the same environment.
- If you prefer an API key over logging in, set `ANTHROPIC_API_KEY` in Windows; `pvim` passes it in.
  (`GH_TOKEN` / `GITHUB_TOKEN` are passed in too, for the GitHub CLI `gh`.)
- You can also keep running Claude Code (or any AI tool) on Windows, on the same folder: Neovim
  reloads the files it changes.

## Debugging

1. Open the file, put the cursor on a line, press `F9` (breakpoint).
2. Press `F5` and choose **file** (Python) or **Launch file** (JavaScript, TypeScript; `.ts` files
   run through [tsx](https://tsx.is), which is preinstalled).
3. Step with `F10` (over), `F11` (into; Windows Terminal uses F11 for full screen, so you may prefer
   `Space di`), `Shift+F11` (out). Inspect values with `Space de` or hover. `Shift+F5` stops.

Python tests: `Space tt` runs the file's tests, `Space td` debugs the nearest one.

## Customizing

Everything is in [nvim/](nvim/), mounted live; changes apply the next time you start `pvim`.
You can edit it from Windows, or inside Neovim with `Space fc` (find config file).

| File                                                         | What's in it                                                            |
| ------------------------------------------------------------ | ----------------------------------------------------------------------- |
| [nvim/lazyvim.json](nvim/lazyvim.json)                       | Enabled LazyVim extras. Easiest: run `:LazyExtras` and press `x` on one |
| [nvim/lua/config/options.lua](nvim/lua/config/options.lua)   | Editor options, clipboard, Python venv detection                        |
| [nvim/lua/config/keymaps.lua](nvim/lua/config/keymaps.lua)   | Extra shortcuts                                                         |
| [nvim/lua/config/autocmds.lua](nvim/lua/config/autocmds.lua) | Auto-reload of changed files, quit fix                                  |
| [nvim/lua/plugins/](nvim/lua/plugins/)                       | Themes, Claude, debugger keys, git review, languages                    |
| [nvim/cheatsheet.md](nvim/cheatsheet.md)                     | The F1 cheat sheet; add your own notes                                  |
| [docker/Dockerfile](docker/Dockerfile)                       | System tools in the image (`pvim -Build` after editing)                 |

More languages: `:LazyExtras` has Go, Rust, Java, C#, PHP, Ruby and many more. Languages that need
a compiler or runtime (Go, Rust, Java, …) also need it in the Dockerfile.

## Updating

- `pvim -Update` rebuilds the image with the newest Neovim, lazygit, fzf, uv, GitHub CLI and Node LTS,
  then updates plugins, language tools and Claude Code. New plugin versions are written to
  [nvim/lazy-lock.json](nvim/lazy-lock.json); commit it to keep other machines on the same versions.
- Claude Code also updates itself.
- Only plugins: `Space l`, then `U`.

## Troubleshooting

| Problem                                 | Fix                                                                      |
| --------------------------------------- | ------------------------------------------------------------------------ |
| "Docker Desktop isn't running"          | Start Docker Desktop (`pvim` tries to start it for you)                  |
| Icons show as boxes or question marks   | Set a Nerd Font in your terminal profile (the installer prints its name) |
| `Ctrl+V` pastes instead of block select | That's Windows Terminal; use `Ctrl+Q` for block selection                |
| `F11` switches to full screen           | Use `Space di`, or remove F11 under Windows Terminal Settings → Actions  |
| Copy to Windows clipboard doesn't work  | Use Windows Terminal (the old console window can't do it)                |
| A language server or parser is missing  | `pvim -Setup`, or `:Mason` / `:TSInstall <language>` inside Neovim       |
| Anything else                           | `:checkhealth` inside Neovim; worst case `pvim -Reset`                   |

## Uninstall

1. Remove `...\perfect-vim\bin` from your user PATH (Settings → "Edit environment variables for your account").
2. `docker volume rm perfect-vim-home` and `docker image rm perfect-vim`
3. Delete `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\PerfectVim`
4. Delete this folder.

## What's inside

```text
perfect-vim/
├─ install.cmd / install.ps1   one-time setup
├─ bin/pvim.cmd                the pvim command (this folder is on your PATH)
├─ lib/pvim.ps1                what pvim does (mounts, git settings, docker run)
├─ docker/
│  ├─ Dockerfile               Debian + Node LTS + Python + Neovim, ripgrep, fd, fzf, lazygit, uv, tsx, gh, tree-sitter
│  ├─ entrypoint.sh            runs at each start (first-run setup, SSH keys)
│  ├─ setup.sh                 installs/updates plugins, language tools, Claude Code
│  ├─ warmup.lua               headless install of language servers and parsers
│  └─ bashrc.sh                shell defaults (fzf, prompt, aliases)
└─ nvim/                       Neovim config (LazyVim)
```
