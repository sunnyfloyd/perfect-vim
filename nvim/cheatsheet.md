# Perfect Vim Cheat Sheet

**Space** is the leader key: `Space ff` means press Space, then f, then f.
Stuck? Press **Space** and wait: a menu shows every possible next key.
`Space sk` searches all shortcuts. `:Tutor` is a 30-minute interactive Vim lesson.

## Survival

| Keys              | What it does                                                              |
| ----------------- | ------------------------------------------------------------------------- |
| `i` `a` `o`       | Insert before cursor / after cursor / on a new line below                 |
| `Esc`             | Back to Normal mode                                                       |
| `Ctrl+S` or `:w`  | Save                                                                      |
| `Space qq`, `:qa` | Quit (asks about unsaved files) · `:qa!` quit without saving              |
| `u` / `Ctrl+R`    | Undo / redo (undo history survives restarts)                              |
| `.`               | Repeat the last change                                                    |
| `v` `V` `Ctrl+Q`  | Select characters / lines / a block (`Ctrl+V` pastes in Windows Terminal) |

## Moving around

| Keys                | What it does                                               |
| ------------------- | ---------------------------------------------------------- |
| `h` `j` `k` `l`     | Left / down / up / right                                   |
| `w` `b` `e`         | Next word / previous word / end of word                    |
| `0` `^` `$`         | Line start / first character / line end                    |
| `gg` `G` `42G`      | Top of file / bottom / line 42                             |
| `Ctrl+D` `Ctrl+U`   | Half a page down / up                                      |
| `%`                 | Jump to the matching bracket                               |
| `s` + 2 letters     | Flash: jump anywhere on screen, then type the shown label  |
| `f`x / `t`x         | Jump to / just before the next "x" on the line (`;` again) |
| `Ctrl+O` / `Ctrl+I` | Back / forward through places you jumped to                |
| `]f` `[f` `]c` `[c` | Next / previous function, class                            |

## Editing: verb + target

| Keys                    | What it does                                                             |
| ----------------------- | ------------------------------------------------------------------------ |
| `d` `c` `y` + motion    | Delete / change / copy (yank). `dw` delete word, `c$` change to line end |
| `dd` `cc` `yy`          | Delete / change / copy the whole line                                    |
| `ciw` `ci"` `ci(` `cit` | Change inside word / quotes / parentheses / HTML tag                     |
| `daf` `vif` `yac`       | Delete a function / select inside function / copy a class                |
| `p` `P`                 | Paste after / before                                                     |
| `x`                     | Delete the character under the cursor                                    |
| `>>` `<<`               | Indent / unindent (in Visual mode: `>` `<`)                              |
| `gcc` / `gc`            | Toggle comment on line / selection                                       |
| `Alt+J` `Alt+K`         | Move line (or selection) down / up                                       |
| `J`                     | Join the next line onto this one                                         |
| `~`                     | Toggle upper/lower case                                                  |

**Clipboard:** `y` also copies to the Windows clipboard. To paste _from_ Windows use
`Ctrl+V` or right-click (in Insert mode). `p` pastes what you last copied in Neovim.

## Search and replace

| Keys            | What it does                                               |
| --------------- | ---------------------------------------------------------- |
| `/text` `?text` | Search forward / backward, `n` `N` next / previous         |
| `*`             | Search the word under the cursor                           |
| `:%s/old/new/g` | Replace in the whole file (`gc` at the end asks each time) |
| `Space sr`      | Search and replace across all files                        |

## Finding files and code (fuzzy search)

| Keys                    | What it does                                   |
| ----------------------- | ---------------------------------------------- |
| `Space Space`           | Find a file by name                            |
| `Space /`               | Search text in all files (grep)                |
| `Space ,`               | Switch between open files (buffers)            |
| `Space fr`              | Recent files                                   |
| `Space sw`              | Search the word under the cursor in all files  |
| `Space ss` / `Space sS` | Symbols (functions, classes) in file / project |
| `Space sd`              | All errors and warnings                        |
| `Space sR`              | Resume the last search                         |
| `Space sk` / `Space sh` | Search shortcuts / help pages                  |

In a search window: type to filter · `Ctrl+J` `Ctrl+K` or arrows to move · `Enter` open ·
`Ctrl+S` open in a split · `Esc` close.

## File explorer: `Space e`

| Keys          | What it does                                             |
| ------------- | -------------------------------------------------------- |
| `l` / `Enter` | Open file / expand folder                                |
| `h`           | Collapse folder                                          |
| `a`           | New file (end the name with `/` for a folder)            |
| `r` `d`       | Rename / delete                                          |
| `c` `m`       | Copy / move                                              |
| `H`           | Show hidden files                                        |
| `/`           | Filter                                                   |
| `Space as`    | Add the file under the cursor to the Claude conversation |
| `?` / `q`     | All explorer keys / close                                |

## Windows and buffers

| Keys                    | What it does                                                                    |
| ----------------------- | ------------------------------------------------------------------------------- |
| `Ctrl+W v` / `Space -`  | Split right / below                                                             |
| `Ctrl+H/J/K/L`          | Move to the window on the left/below/above/right (also out of the Claude panel) |
| `Space wd` / `Space wm` | Close window / zoom it (toggle)                                                 |
| `Ctrl+Arrows`           | Resize the window                                                               |
| `Shift+H` / `Shift+L`   | Previous / next open file                                                       |
| `Space bd` / `Space bo` | Close this file / close all other files                                         |

## Code intelligence (Python, TypeScript, JavaScript, Markdown, JSON, YAML, …)

| Keys                    | What it does                                          |
| ----------------------- | ----------------------------------------------------- |
| `gd` / `gr`             | Go to definition / list references                    |
| `gI` / `gy`             | Go to implementation / type definition                |
| `K` / `gK`              | Documentation / function signature                    |
| `Space ca`              | Code action: quick fixes, add import, …               |
| `Space cr`              | Rename everywhere                                     |
| `Space cf`              | Format the file (also runs on save)                   |
| `Space co`              | Organize imports                                      |
| `]d` `[d` / `]e` `[e`   | Next / previous problem / error                       |
| `Space cd`              | Show the problem on this line                         |
| `Space xx`              | List of all problems (Trouble)                        |
| `Space cs`              | Outline of symbols                                    |
| `Space cv`              | Choose the Python virtualenv                          |
| `Space cm` / `Space cl` | Mason (install language tools) / language server info |

Completion pops up while typing: arrows or `Ctrl+N` `Ctrl+P` to choose, `Enter` to accept,
`Ctrl+Space` to open it, `Ctrl+E` to close it. `Tab` jumps to the next snippet field.

## AI: Claude Code

| Keys                    | What it does                                                 |
| ----------------------- | ------------------------------------------------------------ |
| `Space ac`              | Open / close the Claude panel                                |
| `Space af`              | Jump into the Claude panel                                   |
| `Space ab`              | Add the current file to the conversation                     |
| `Space as`              | Send the selection (Visual mode) to Claude                   |
| `Space aa` / `Space ad` | Accept / reject the change Claude proposes (shown as a diff) |
| `Space aC` / `Space ar` | Continue the last conversation / pick an older one           |
| `Space am`              | Choose the model                                             |

Inside the panel: type normally · `Ctrl+H` back to your code · `Esc` interrupts Claude ·
`Esc Esc` (quickly) switches to Normal mode to scroll and copy, `i` to type again.
Claude sees which file you are in and what you selected.

**Reviewing what Claude (or anyone) changed:** files reload on their own when changed on disk.

| Keys                      | What it does                                               |
| ------------------------- | ---------------------------------------------------------- |
| `Space gv`                | Side-by-side review of every changed file (again to close) |
| `]h` `[h`                 | Next / previous changed block                              |
| `Space ghp`               | Preview the change under the cursor                        |
| `Space ghr` / `Space ghs` | Undo / stage that change                                   |
| `Space gg`                | lazygit: stage, commit, push (`?` inside for help)         |

## Git

| Keys                    | What it does                          |
| ----------------------- | ------------------------------------- |
| `Space gg`              | lazygit                               |
| `Space gv` / `Space gH` | Review changes / history of this file |
| `Space gb`              | Who changed this line (blame)         |
| `Space gs` / `Space gl` | Status / commits                      |
| `Space ghb`             | Blame with the full commit message    |

## Debugging and tests

| Keys                      | What it does                                                       |
| ------------------------- | ------------------------------------------------------------------ |
| `F5`                      | Start / continue (pick `file` for Python, `Launch file` for JS/TS) |
| `F9`                      | Toggle breakpoint (`Space dB`: with a condition)                   |
| `F10`                     | Step over                                                          |
| `F11` or `Space di`       | Step into (Windows Terminal uses F11 for full screen)              |
| `Shift+F11` or `Space do` | Step out                                                           |
| `Shift+F5` or `Space dt`  | Stop                                                               |
| `Space dC`                | Run to the cursor                                                  |
| `Space da`                | Run with arguments                                                 |
| `Space du`                | Show / hide the debugger panels                                    |
| `Space de`                | Evaluate the expression under the cursor (or selection)            |
| `Space dr`                | Debug console (REPL)                                               |
| `Space tt` / `Space tr`   | Run tests in this file / the nearest test                          |
| `Space td`                | Debug the nearest test                                             |
| `Space ts` / `Space to`   | Test summary / test output                                         |

Python runs in the project's Linux virtualenv (`.venv`, `venv` or `.venv-linux`).

## Terminal

| Keys           | What it does                                             |
| -------------- | -------------------------------------------------------- |
| `Ctrl+/`       | Floating terminal (toggle)                               |
| `Esc Esc`      | Terminal → Normal mode (scroll, copy); `i` to type again |
| `Ctrl+H/J/K/L` | Leave the terminal for another window                    |

## Look and feel

| Keys                    | What it does                              |
| ----------------------- | ----------------------------------------- |
| `Space uC`              | Choose a theme (live preview, remembered) |
| `Space ub`              | Dark / light background                   |
| `Space uw`              | Wrap long lines                           |
| `Space ul` / `Space uL` | Line numbers / relative line numbers      |
| `Space us`              | Spell check                               |
| `Space um`              | Render Markdown nicely                    |
| `Space uf`              | Format on save on / off                   |
| `Space ud` / `Space uh` | Problems on / off / inline type hints     |
| `Space uz`              | Zen mode                                  |

## Housekeeping

| Keys                    | What it does                                            |
| ----------------------- | ------------------------------------------------------- |
| `Space qs` / `Space ql` | Restore the session for this folder / the last session  |
| `Space l`               | Plugins (`U` updates them)                              |
| `:LazyExtras`           | Turn on more languages and features (Go, Rust, Java, …) |
| `Space n`               | Notification history                                    |
| `:checkhealth`          | Diagnose problems                                       |

## Docker and Windows

- Your folder is at `/workspace/<folder name>`. Edits show up in Windows right away, and the other way round.
- Kept between sessions: plugins, language tools, Claude login, shell history, undo history, theme.
  Lost on exit: anything installed with `sudo apt install` (add it to the Dockerfile instead).
- Web dev servers: start with `pvim -Port 3000` and run the server with `--host 0.0.0.0`.
- `pvim -Shell` opens a plain shell, `pvim -Claude` starts Claude Code without the editor.
