-- Perfect Vim trainer: learn the editor by doing. Open it with <leader>T or :Trainer.
--   Drills  real editing in a practice buffer, checked automatically and scored by
--           the number of keys you pressed (drill.lua, exercises in lessons.lua)
--   Quiz    "which keys do X?": you press the keys, spaced repetition brings back
--           the ones you don't know yet (quiz.lua, questions in cards.lua)
-- Progress is saved in ~/.local/state/nvim/pvim-trainer.json (kept between sessions).
local M = {}

M.ns = vim.api.nvim_create_namespace("pvim_trainer")

-- Saved progress -------------------------------------------------------------------
local state_file = vim.fn.stdpath("state") .. "/pvim-trainer.json"
local data ---@type {drills: table<string, table<string, integer>>, cards: table<string, table>, session: integer}?

function M.state()
  if not data then
    local ok, decoded = pcall(function()
      local f = assert(io.open(state_file, "r"))
      local text = f:read("*a")
      f:close()
      return vim.json.decode(text)
    end)
    data = ok and type(decoded) == "table" and decoded or {}
    data.drills = type(data.drills) == "table" and data.drills or {}
    data.cards = type(data.cards) == "table" and data.cards or {}
    data.session = tonumber(data.session) or 0
  end
  return data
end

function M.save()
  local f = io.open(state_file, "w")
  if f then
    f:write(vim.json.encode(M.state()))
    f:close()
  end
end

-- Keys ----------------------------------------------------------------------------
-- Split key notation into keys: "<leader>ff" -> { "<leader>", "f", "f" }
function M.split(keys)
  local out, i = {}, 1
  while i <= #keys do
    local key = keys:match("^<%a[%w%-_/]*>", i) or keys:match("^[\1-\127\194-\244][\128-\191]*", i)
    key = (key and key ~= "") and key or keys:sub(i, i)
    out[#out + 1] = key
    i = i + #key
  end
  return out
end

local aliases = {
  [" "] = "<space>",
  ["<leader>"] = "<space>",
  ["<lt>"] = "<",
  ["<bar>"] = "|",
  ["<bslash>"] = "\\",
  ["<c-_>"] = "<c-/>", -- Ctrl+/ arrives as Ctrl+_ in most terminals
  ["<f17>"] = "<s-f5>", -- Shift+F5 / Shift+F11 in some terminals
  ["<f23>"] = "<s-f11>",
  ["<c-i>"] = "<tab>",
  ["<nl>"] = "<c-j>",
  ["<c-m>"] = "<cr>",
  ["<return>"] = "<cr>",
  ["<enter>"] = "<cr>",
}

-- One canonical spelling per key, to compare what you typed with the answer
function M.norm(key)
  if #key > 2 and key:sub(1, 1) == "<" then
    key = key:lower():gsub("^<a%-", "<m-")
  end
  return aliases[key] or key
end

-- Mouse and focus events are not keys you pressed on purpose
function M.noise(key)
  local k = key:lower()
  for _, word in ipairs({ "mouse", "scrollwheel", "release", "drag", "focus", "paste", "ignore", "cursorhold", "nop" }) do
    if k:find(word, 1, true) then
      return true
    end
  end
  return false
end

local names = { ["<space>"] = "Space", ["<cr>"] = "Enter", ["<esc>"] = "Esc", ["<bs>"] = "Backspace", ["<tab>"] = "Tab" }

local function keyname(k) -- "<c-w>" -> "Ctrl+W", "<m-j>" -> "Alt+J", "<s-f5>" -> "Shift+F5"
  if names[k] then
    return names[k]
  end
  local parts, base = {}, k:sub(2, -2)
  while true do
    local mod, rest = base:match("^([csm])%-(.+)$")
    if not mod then
      break
    end
    parts[#parts + 1] = ({ c = "Ctrl", s = "Shift", m = "Alt" })[mod]
    base = rest
  end
  parts[#parts + 1] = names["<" .. base .. ">"] or base:upper()
  return table.concat(parts, "+")
end

-- Keys as you would say them: "<leader>ghp" -> "Space ghp", "ciwfoo<Esc>" -> "ciwfoo Esc"
function M.pretty(keys)
  local parts, plain = {}, ""
  local function flush()
    if plain ~= "" then
      parts[#parts + 1] = plain
      plain = ""
    end
  end
  for _, key in ipairs(type(keys) == "table" and keys or M.split(keys)) do
    local k = M.norm(key)
    if key == " " then
      plain = plain .. "␣" -- a space typed as text
    elseif #k > 2 and k:sub(1, 1) == "<" then
      flush()
      parts[#parts + 1] = keyname(k)
    else
      plain = plain .. k
    end
  end
  flush()
  return table.concat(parts, " ")
end

-- Drawing -------------------------------------------------------------------------
function M.highlights()
  local function set(name, link)
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
  set("PvimTrainerTitle", "Title")
  set("PvimTrainerKey", "Special")
  set("PvimTrainerDim", "Comment")
  set("PvimTrainerGoal", "String")
  set("PvimTrainerOk", "DiagnosticOk")
  set("PvimTrainerBad", "DiagnosticError")
  set("PvimTrainerStar", "DiagnosticWarn")
  set("PvimTrainerTarget", "IncSearch")
end

-- "Press `dd` to delete" -> chunks, with the `keys` highlighted
function M.md(text, hl)
  local chunks = {}
  for i, part in ipairs(vim.split(text, "`", { plain = true })) do
    if part ~= "" then
      chunks[#chunks + 1] = { part, i % 2 == 0 and "PvimTrainerKey" or hl }
    end
  end
  return chunks
end

-- rows: list of strings or lists of { text, highlight } chunks
function M.render(buf, rows)
  local lines, marks = {}, {}
  for i, row in ipairs(rows) do
    local line = ""
    for _, chunk in ipairs(type(row) == "string" and { { row } } or row) do
      if chunk[2] then
        marks[#marks + 1] = { i - 1, #line, #line + #chunk[1], chunk[2] }
      end
      line = line .. chunk[1]
    end
    lines[i] = line
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, M.ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
end

-- Screen lines a buffer needs in a window of this width (long lines wrap)
function M.height(buf, width)
  local h = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    h = h + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / math.max(width, 1)))
  end
  return h
end

function M.set_wo(win, opts)
  for name, value in pairs(opts) do
    pcall(vim.api.nvim_set_option_value, name, value, { scope = "local", win = win })
  end
end

-- Menu ----------------------------------------------------------------------------
local function pad(text, width) -- by display width: "ś" is 2 bytes but 1 column
  return text .. (" "):rep(math.max(0, width - vim.fn.strdisplaywidth(text)))
end

function M.lesson_progress(lesson)
  local rec = M.state().drills[lesson.id] or {}
  local done, stars = 0, 0
  for i = 1, #lesson.exercises do
    local s = tonumber(rec[tostring(i)])
    if s then
      done, stars = done + 1, stars + s
    end
  end
  return done, stars
end

-- First exercise of the lesson not done yet (nil: all done)
local function first_open(lesson)
  local rec = M.state().drills[lesson.id] or {}
  for ei = 1, #lesson.exercises do
    if not rec[tostring(ei)] then
      return ei
    end
  end
end

local function select(items, prompt)
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      vim.schedule(item.run)
    end
  end)
end

local function quiz_topics()
  local quiz = require("config.trainer.quiz")
  local items = {}
  for _, cat in ipairs(require("config.trainer.cards")) do
    local c = quiz.counts(cat.id)
    items[#items + 1] = {
      label = ("%s %3d pytań · opanowane %d"):format(pad(cat.name, 24), c.total, c.mastered),
      run = function()
        quiz.start({ category = cat.id })
      end,
    }
  end
  select(items, "Quiz: wybierz temat")
end

local function confirm_reset()
  select({
    { label = "Nie, zostaw", run = M.open },
    {
      label = "Tak, usuń gwiazdki i postęp quizu",
      run = function()
        data = { drills = {}, cards = {}, session = 0 }
        M.save()
        vim.notify("Postęp wyzerowany", vim.log.levels.INFO, { title = "Trening" })
      end,
    },
  }, "Wyzerować cały postęp?")
end

function M.open()
  local lessons = require("config.trainer.lessons")
  local drill = require("config.trainer.drill")
  local quiz = require("config.trainer.quiz")
  local items = {}

  for li, lesson in ipairs(lessons) do
    local ei = first_open(lesson)
    if ei then
      items[#items + 1] = {
        label = ("▶ Dalej: lekcja %d · %s, ćwiczenie %d/%d"):format(li, lesson.title, ei, #lesson.exercises),
        run = function()
          drill.start(li, ei)
        end,
      }
      break
    end
  end
  for li, lesson in ipairs(lessons) do
    local done, stars = M.lesson_progress(lesson)
    local n = #lesson.exercises
    items[#items + 1] = {
      label = ("Lekcja %d · %s %s %2d/%-2d  ★ %d/%d"):format(li, pad(lesson.title, 34), done == n and "✔" or " ", done, n, stars, 3 * n),
      run = function()
        drill.start(li, first_open(lesson) or 1) -- resume where you left off
      end,
    }
  end
  local c = quiz.counts()
  items[#items + 1] = {
    label = ("⌨ Quiz skrótów (do powtórki: %d, nowe: %d, opanowane: %d/%d)"):format(c.due, c.new, c.mastered, c.total),
    run = function()
      quiz.start()
    end,
  }
  items[#items + 1] = { label = "⌨ Quiz skrótów: wybierz temat…", run = quiz_topics }
  items[#items + 1] = { label = "  Wyzeruj postęp", run = confirm_reset }
  select(items, "Trening Perfect Vim")
end

return M
