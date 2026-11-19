-- Drill runner. Opens a tab with the task on top and a practice buffer below. You
-- edit the buffer with real Vim (all your keymaps and plugins work); as soon as the
-- text, or the cursor position, matches the goal and you are back in Normal mode,
-- the exercise is done and scored by the number of keys you pressed.
local T = require("config.trainer")
local lessons = require("config.trainer.lessons")

local M = {}

local CURSOR, TARGET = "▌", "◆" -- markers in an exercise's `text`
local key_ns = vim.api.nvim_create_namespace("pvim_trainer_keys")
local S ---@type table? the running session

local function solutions(ex)
  return type(ex.keys) == "table" and ex.keys or { ex.keys }
end

local function par(ex)
  return ex.par or #T.split(solutions(ex)[1])
end

local function stars_for(keys, best, hinted)
  local s = keys <= best and 3 or keys <= best + math.max(best, 2) and 2 or 1
  return hinted and math.min(s, 2) or s
end

local function star_text(s)
  return ("★"):rep(s) .. ("☆"):rep(3 - s)
end

local function n_keys(n) -- Polish plural: 1 klawisz, 2 klawisze, 5 klawiszy, 22 klawisze
  local word = "klawiszy"
  if n == 1 then
    word = "klawisz"
  elseif n % 10 >= 2 and n % 10 <= 4 and (n % 100 < 12 or n % 100 > 14) then
    word = "klawisze"
  end
  return n .. " " .. word
end

-- Remove the ▌ / ◆ markers and remember where they were (byte columns, UTF-8 safe)
local function parse(text)
  local lines, cursor, target = {}, nil, nil
  for row, line in ipairs(text) do
    local c, t = line:find(CURSOR, 1, true), line:find(TARGET, 1, true)
    if c and t then
      if c < t then
        t = t - #CURSOR
      else
        c = c - #TARGET
      end
    end
    if c then
      cursor = { row, c - 1 }
    end
    if t then
      target = { row, t - 1 }
    end
    lines[row] = line:gsub(CURSOR, ""):gsub(TARGET, "")
  end
  return lines, cursor or { 1, 0 }, target
end

-- Trailing spaces and trailing empty lines never count; `loose` ignores all blank lines
local function same(a, b, loose)
  local function clean(lines)
    local out = {}
    for _, l in ipairs(lines) do
      l = l:gsub("%s+$", "")
      if not (loose and l == "") then
        out[#out + 1] = l
      end
    end
    while #out > 0 and out[#out] == "" do
      out[#out] = nil
    end
    return out
  end
  return vim.deep_equal(clean(a), clean(b))
end

-- Info window ----------------------------------------------------------------------
local function footer(items)
  local row = { { " " } }
  for _, item in ipairs(items) do
    row[#row + 1] = { item[1], "PvimTrainerKey" }
    row[#row + 1] = { " " .. item[2] .. "   ", "PvimTrainerDim" }
  end
  return row
end

local function info_rows()
  local ex, lesson = S.ex, S.lesson
  local rows = {}
  local function add(row)
    rows[#rows + 1] = row
  end
  add({
    { (" Lekcja %d/%d · %s"):format(S.li, #lessons, lesson.title), "PvimTrainerTitle" },
    {
      S.state == "lesson_done" and "   ukończona!" or ("   ćwiczenie %d/%d"):format(S.ei, #lesson.exercises),
      "PvimTrainerDim",
    },
  })

  if S.state == "lesson_done" then
    local done, stars = T.lesson_progress(lesson)
    add("")
    add({
      { (" ✔ Zrobione %d/%d   "):format(done, #lesson.exercises), "PvimTrainerOk" },
      { ("★ %d/%d"):format(stars, 3 * #lesson.exercises), "PvimTrainerStar" },
    })
    add("")
    local nxt = lessons[S.li + 1]
    add(footer({
      { "Enter", nxt and ("następna lekcja: " .. nxt.title) or "koniec (to była ostatnia lekcja)" },
      { "F3", "powtórz lekcję" },
      { ":q", "wyjdź" },
    }))
    return rows
  end

  if S.ei == 1 and lesson.intro then
    for _, line in ipairs(lesson.intro) do
      add(T.md(" " .. line, "PvimTrainerDim"))
    end
  end
  add("")
  local task = T.md(ex.task)
  table.insert(task, 1, { " ▶ ", "PvimTrainerKey" })
  add(task)
  if ex.want and #ex.want <= 8 then
    for i, line in ipairs(ex.want) do
      add({ { i == 1 and "   cel:  " or "         ", "PvimTrainerDim" }, { line, "PvimTrainerGoal" } })
    end
  elseif S.target then
    add({ { "   cel:  ", "PvimTrainerDim" }, { "kursor na podświetlonym znaku", "PvimTrainerGoal" } })
  end
  add("")

  if S.state == "done" then
    add({
      { " ✔ Brawo!  ", "PvimTrainerOk" },
      { star_text(S.stars), "PvimTrainerStar" },
      { ("   %s (★★★ za ≤ %d)"):format(n_keys(S.keys), S.par), "PvimTrainerDim" },
    })
    local best = { { "   najkrócej:  ", "PvimTrainerDim" }, { ex.show or T.pretty(solutions(ex)[1]), "PvimTrainerKey" } }
    for i = 2, #solutions(ex) do
      best[#best + 1] = { i == 2 and "   albo:  " or "   ", "PvimTrainerDim" }
      best[#best + 1] = { T.pretty(solutions(ex)[i]), "PvimTrainerKey" }
    end
    add(best)
    if ex.hint then
      add(T.md("   " .. ex.hint, "PvimTrainerDim"))
    end
    add("")
    add(footer({ { "Enter", "dalej" }, { "F3", "jeszcze raz" }, { ":q", "wyjdź" } }))
    return rows
  end

  add({
    { " klawisze: ", "PvimTrainerDim" },
    { tostring(S.keys), "PvimTrainerKey" },
    { ("   ★★★ za ≤ %d"):format(S.par), "PvimTrainerDim" },
  })
  if S.warn then
    add(T.md(" " .. S.warn, "PvimTrainerBad"))
  end
  if S.hints >= 1 and ex.hint then
    add(T.md(" podpowiedź: " .. ex.hint, "PvimTrainerDim"))
  end
  if S.hints >= 2 or (S.hints >= 1 and not ex.hint) then
    add({ { " rozwiązanie: ", "PvimTrainerDim" }, { ex.show or T.pretty(solutions(ex)[1]), "PvimTrainerKey" } })
  end
  add("")
  add(footer({ { "F2", "podpowiedź" }, { "F3", "od nowa" }, { "F4", "pomiń" }, { "F1", "ściąga" }, { ":q", "wyjdź" } }))
  return rows
end

local function render()
  if not (S and vim.api.nvim_buf_is_valid(S.info_buf) and vim.api.nvim_win_is_valid(S.info_win)) then
    return
  end
  T.render(S.info_buf, info_rows())
  local h = T.height(S.info_buf, vim.api.nvim_win_get_width(S.info_win))
  pcall(vim.api.nvim_win_set_height, S.info_win, math.min(h, math.floor(vim.o.lines / 2)))
end

local render_pending = false
local function render_soon()
  if not render_pending then
    render_pending = true
    vim.schedule(function()
      render_pending = false
      pcall(render)
    end)
  end
end

-- Checking ---------------------------------------------------------------------------
local function success()
  S.state = "done"
  S.stars = stars_for(S.keys, S.par, S.hints > 0)
  local st = T.state()
  st.drills[S.lesson.id] = st.drills[S.lesson.id] or {}
  local rec, k = st.drills[S.lesson.id], tostring(S.ei)
  rec[k] = math.max(tonumber(rec[k]) or 0, S.stars)
  T.save()
  vim.bo[S.buf].modifiable = false
  vim.keymap.set("n", "<CR>", M.next, { buffer = S.buf, nowait = true, desc = "Trainer: next" })
  render()
end

function M.check()
  if not S or S.state ~= "run" or vim.api.nvim_get_current_buf() ~= S.buf then
    return
  end
  if vim.api.nvim_get_mode().mode ~= "n" then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(S.buf, 0, -1, false)
  local ex = S.ex
  local text_ok = same(lines, ex.want or S.start_lines, ex.loose)
  local warn = nil
  if S.target and not ex.want and not text_ok then
    warn = "Tekst się zmienił, a tu chodzi tylko o ruch kursora: `u` cofa, `F3` zaczyna od nowa."
  end
  if warn ~= S.warn then
    S.warn = warn
    render_soon()
  end
  local ok = text_ok
  if ok and S.target then
    local c = vim.api.nvim_win_get_cursor(S.win)
    ok = c[1] == S.target[1] and c[2] == S.target[2]
  end
  if ok then
    success()
  end
end

local check_pending = false
local function check_soon()
  if not check_pending then
    check_pending = true
    vim.schedule(function()
      check_pending = false
      M.check()
    end)
  end
end

-- which-key catches prefixes like `g`, reads the next keys itself and then replays all
-- of them as if typed again (with its triggers suspended). Those were counted already.
local function which_key()
  local state = package.loaded["which-key.state"]
  local triggers = package.loaded["which-key.triggers"]
  local reading = type(state) == "table" and type(state.state) == "table" and state.state or nil
  local replaying = type(triggers) == "table" and type(triggers.suspended) == "table" and next(triggers.suspended) ~= nil
  return reading, replaying
end

-- Count the keys you press in the practice window
local function on_key(_, typed)
  if not S or S.state ~= "run" or not typed or typed == "" or vim.api.nvim_get_current_win() ~= S.win then
    return
  end
  local n = 0
  for _, key in ipairs(T.split(vim.fn.keytrans(typed))) do
    if not T.noise(key) and not key:match("^<F[1-4]>$") then
      n = n + 1
    end
  end
  if n == 0 then
    return
  end
  local reading, replaying = which_key()
  if reading then
    -- which-key will replay the keys it has read so far, this one, and a count
    local node, mode = reading.node or {}, reading.mode and reading.mode.mode or "n"
    S.replay = (node.path and #node.path or #T.split(node.keys or "")) + n
    if vim.v.count > 0 and not vim.tbl_contains({ "x", "o", "i", "c" }, mode) then
      S.replay = S.replay + #tostring(vim.v.count)
    end
  elseif S.replay > 0 and replaying then
    -- `typed` can hold replayed keys followed by a new one ("gc" + "c" for gcc)
    local skip = math.min(S.replay, n)
    S.replay, n = S.replay - skip, n - skip
  else
    S.replay = 0
  end
  if n > 0 then
    S.keys = S.keys + n
    render_soon()
  end
end

-- Buffers ----------------------------------------------------------------------------
local function show(buf)
  if vim.api.nvim_win_is_valid(S.win) then
    vim.api.nvim_set_current_win(S.win)
  end
  T.set_wo(S.win, { winfixbuf = false })
  vim.api.nvim_win_set_buf(S.win, buf)
  T.set_wo(S.win, { winfixbuf = true })
  S.buf = buf
end

local function new_buf(lines, before)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  -- The starting text is not part of the undo history (`u` can't empty the buffer)
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, before or lines)
  vim.bo[buf].undolevels = -123456 -- back to the global value
  if before then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) -- the change the undo drill undoes
  end
  -- Predictable text: no completion popup, no auto-closed brackets, no format on save
  vim.b[buf].completion = false
  vim.b[buf].minipairs_disable = true
  vim.b[buf].autoformat = false
  return buf
end

-- Wrap a control key: leave Insert/Visual mode first, then act
local function control(fn)
  return function()
    local mode = vim.api.nvim_get_mode().mode
    if mode:match("^[vVsS\22\19]") then
      vim.cmd("normal! " .. vim.keycode("<Esc>"))
    end
    vim.cmd.stopinsert()
    vim.schedule(fn)
  end
end

local function map_controls(buf)
  local function bmap(lhs, fn, desc)
    vim.keymap.set({ "n", "i", "x", "s" }, lhs, control(fn), { buffer = buf, nowait = true, desc = "Trainer: " .. desc })
  end
  bmap("<F2>", M.hint, "hint")
  bmap("<F3>", M.restart, "start over")
  bmap("<F4>", M.skip, "skip")
end

local function load_exercise()
  local ex = S.lesson.exercises[S.ei]
  local lines, cursor, target = parse(ex.text)
  S.ex, S.start_lines, S.target = ex, lines, target
  S.keys, S.hints, S.state, S.stars, S.warn, S.replay = 0, 0, "run", nil, nil, 0
  S.par = par(ex)

  local buf = new_buf(lines, ex.before)
  show(buf)
  -- Set the filetype once the buffer is in the window, so ftplugins set up this window
  vim.bo[buf].filetype = ex.ft or ""
  vim.diagnostic.enable(false, { bufnr = buf })
  pcall(vim.api.nvim_win_set_cursor, S.win, cursor)
  vim.fn.winrestview({ topline = 1, leftcol = 0 })

  if target then
    local line = lines[target[1]]
    local ch = line:sub(target[2] + 1):match("^[\1-\127\194-\244][\128-\191]*") or ""
    local mark = { hl_group = "PvimTrainerTarget", end_col = target[2] + #ch, priority = 200 }
    if ch == "" then
      mark = { virt_text = { { TARGET, "PvimTrainerTarget" } }, virt_text_pos = "overlay" }
    end
    vim.api.nvim_buf_set_extmark(buf, T.ns, target[1] - 1, target[2], mark)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "CursorMoved", "InsertLeave" }, {
    group = S.augroup,
    buffer = buf,
    callback = check_soon,
  })
  map_controls(buf)
  render()
end

local function lesson_done()
  S.state = "lesson_done"
  local rec = T.state().drills[S.lesson.id] or {}
  local lines = { "", "  Wyniki lekcji: " .. S.lesson.title, "" }
  for i, ex in ipairs(S.lesson.exercises) do
    local s = tonumber(rec[tostring(i)])
    local task = ex.task:gsub("`", ""):match("^(.-[.!?:])%s") or ex.task:gsub("`", "")
    lines[#lines + 1] = ("  %s  %2d. %s"):format(s and star_text(s) or "· · ·", i, task)
  end
  local buf = new_buf(lines)
  show(buf)
  vim.bo[buf].modifiable = false
  vim.keymap.set("n", "<CR>", M.next, { buffer = buf, nowait = true, desc = "Trainer: next lesson" })
  map_controls(buf)
  render()
end

-- Controls ---------------------------------------------------------------------------
function M.next()
  if not S then
    return
  end
  if S.state == "lesson_done" then
    if S.li < #lessons then
      S.li, S.ei, S.lesson = S.li + 1, 1, lessons[S.li + 1]
      return load_exercise()
    end
    return M.stop()
  end
  if S.ei < #S.lesson.exercises then
    S.ei = S.ei + 1
    load_exercise()
  else
    lesson_done()
  end
end

function M.skip()
  if S then
    M.next()
  end
end

function M.restart()
  if not S then
    return
  end
  if S.state == "lesson_done" then
    S.ei = 1
  end
  load_exercise()
end

function M.hint()
  if S and S.state == "run" then
    S.hints = S.hints + 1
    render()
  end
end

function M.stop()
  if not S then
    return
  end
  local s = S
  S = nil
  vim.on_key(nil, key_ns)
  pcall(vim.api.nvim_del_augroup_by_id, s.augroup)
  vim.schedule(function()
    if not vim.api.nvim_tabpage_is_valid(s.tab) then
      return
    end
    if #vim.api.nvim_list_tabpages() > 1 then
      pcall(vim.cmd.tabclose, vim.api.nvim_tabpage_get_number(s.tab))
    else
      pcall(vim.api.nvim_win_close, s.info_win, true)
      if vim.api.nvim_win_is_valid(s.win) then
        T.set_wo(s.win, { winfixbuf = false })
        vim.api.nvim_win_call(s.win, vim.cmd.enew)
      end
    end
  end)
end

-- Start ------------------------------------------------------------------------------
local function create_layout()
  vim.cmd.tabnew()
  local win = vim.api.nvim_get_current_win()
  vim.bo.bufhidden = "wipe" -- the empty buffer tabnew made
  T.set_wo(win, { spell = false, wrap = false, foldenable = false, list = false })

  local info_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[info_buf].bufhidden = "wipe"
  vim.bo[info_buf].filetype = "pvim_trainer"
  local info_win = vim.api.nvim_open_win(info_buf, false, { split = "above", win = win, height = 6 })
  T.set_wo(info_win, {
    number = false,
    relativenumber = false,
    cursorline = false,
    signcolumn = "no",
    foldcolumn = "0",
    statuscolumn = "",
    spell = false,
    list = false,
    wrap = true,
    linebreak = true,
    winfixheight = true,
    winfixbuf = true,
  })
  vim.keymap.set("n", "q", M.stop, { buffer = info_buf, nowait = true, desc = "Trainer: quit" })

  local augroup = vim.api.nvim_create_augroup("pvim_trainer_drill", { clear = true })
  S = { tab = vim.api.nvim_get_current_tabpage(), win = win, info_win = info_win, info_buf = info_buf, augroup = augroup }

  -- Back in Normal mode after Visual or the command line: check again
  vim.api.nvim_create_autocmd("ModeChanged", { group = augroup, pattern = "*:n", callback = check_soon })
  -- Closing either window ends the session
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = { tostring(win), tostring(info_win) },
    callback = function()
      M.stop()
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", { group = augroup, callback = render_soon })
  vim.on_key(on_key, key_ns)
end

---@param li integer lesson number
---@param ei? integer exercise number
function M.start(li, ei)
  T.highlights()
  if S and vim.api.nvim_tabpage_is_valid(S.tab) and vim.api.nvim_win_is_valid(S.win) then
    vim.api.nvim_set_current_tabpage(S.tab)
  else
    M.stop()
    create_layout()
  end
  S.li, S.ei, S.lesson = li, ei or 1, lessons[li]
  load_exercise()
end

-- For tests
function M._session()
  return S
end

return M
