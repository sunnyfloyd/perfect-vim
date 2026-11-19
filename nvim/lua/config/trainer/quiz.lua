-- Shortcut quiz. Shows "which keys do X?" in a floating window and reads the keys
-- you press directly (they are not executed), so any key works: Space…, Ctrl+…, F5.
-- Spaced repetition (Leitner boxes): a right answer moves the card up a box and it
-- comes back after 1, 2, 4, 8 or 16 quiz sessions; a wrong one sends it back to box 1
-- and asks it again a few cards later.
local T = require("config.trainer")
local categories = require("config.trainer.cards")

local M = {}

local SESSION = 15 -- cards per review session
local NEW_MIN = 4 -- new cards per session, while there are any
local INTERVAL = { 1, 2, 4, 8, 16 } -- sessions until a card in box N is due again

local function answers(card)
  return type(card.a) == "table" and card.a or { card.a }
end

local function cards(cat_id)
  local out = {}
  for _, cat in ipairs(categories) do
    if not cat_id or cat.id == cat_id then
      for _, card in ipairs(cat.cards) do
        if not card.id then
          card.id = cat.id .. ":" .. card.q
          card.cat = cat.name
          card.norm = {}
          for _, a in ipairs(answers(card)) do
            card.norm[#card.norm + 1] = vim.tbl_map(T.norm, T.split(a))
          end
        end
        out[#out + 1] = card
      end
    end
  end
  return out
end

local function box(card)
  local c = T.state().cards[card.id]
  return c and c.box or 0
end

function M.counts(cat_id)
  local st = T.state()
  local n = { due = 0, new = 0, mastered = 0, total = 0 }
  for _, card in ipairs(cards(cat_id)) do
    local c = st.cards[card.id]
    n.total = n.total + 1
    if not c then
      n.new = n.new + 1
    else
      if (c.due or 0) <= st.session + 1 then
        n.due = n.due + 1
      end
      if (c.box or 0) >= 4 then
        n.mastered = n.mastered + 1
      end
    end
  end
  return n
end

local function shuffle(list)
  for i = #list, 2, -1 do
    local j = math.random(i)
    list[i], list[j] = list[j], list[i]
  end
  return list
end

local function by_box(list)
  shuffle(list)
  table.sort(list, function(a, b)
    return box(a) < box(b)
  end)
  return list
end

local function build_queue(cat_id)
  if cat_id then
    return by_box(cards(cat_id)) -- the whole topic, weakest first
  end
  local st = T.state()
  local due, new, rest = {}, {}, {}
  for _, card in ipairs(cards()) do
    local c = st.cards[card.id]
    if not c then
      new[#new + 1] = card -- in file order: basics first
    elseif (c.due or 0) <= st.session then
      due[#due + 1] = card
    else
      rest[#rest + 1] = card
    end
  end
  local queue = {}
  for _, card in ipairs(by_box(due)) do
    if #queue >= SESSION - math.min(#new, NEW_MIN) then
      break
    end
    queue[#queue + 1] = card
  end
  for _, card in ipairs(new) do
    if #queue >= SESSION then
      break
    end
    queue[#queue + 1] = card
  end
  -- Nothing due and nothing new: practice the cards that are due soonest
  table.sort(rest, function(a, b)
    return st.cards[a.id].due < st.cards[b.id].due
  end)
  for _, card in ipairs(rest) do
    if #queue >= SESSION then
      break
    end
    queue[#queue + 1] = card
  end
  return shuffle(queue)
end

local function record(card, ok)
  local st = T.state()
  local c = st.cards[card.id] or {}
  c.box = ok and math.min((c.box or 1) + 1, #INTERVAL) or 1
  c.due = st.session + INTERVAL[c.box]
  c.right = (c.right or 0) + (ok and 1 or 0)
  c.wrong = (c.wrong or 0) + (ok and 0 or 1)
  st.cards[card.id] = c
end

-- "ok" when typed is an answer, "bad" when no answer starts like this, nil: keep typing
local function match(card, typed)
  local prefix = false
  for _, ans in ipairs(card.norm) do
    local fits = #typed <= #ans
    for i = 1, #typed do
      fits = fits and ans[i] == typed[i]
    end
    if fits and #typed == #ans then
      return "ok"
    end
    prefix = prefix or fits
  end
  return not prefix and "bad" or nil
end

-- Window -----------------------------------------------------------------------------
local function open_ui(title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local width = math.min(78, vim.o.columns - 4)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = 8,
    row = math.max(1, math.floor(vim.o.lines * 0.25)),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    zindex = 200,
  })
  T.set_wo(win, { wrap = true, linebreak = true })
  return { buf = buf, win = win, width = width }
end

local function draw(ui, rows)
  T.render(ui.buf, rows)
  vim.api.nvim_win_set_config(ui.win, { height = math.min(T.height(ui.buf, ui.width), vim.o.lines - 4) })
  vim.cmd.redraw()
end

local function getkey()
  while true do
    local ok, ch = pcall(vim.fn.getcharstr)
    if not ok or ch == "\3" then
      return "<c-c>"
    end
    local key = T.norm(vim.fn.keytrans(ch))
    if not T.noise(key) then
      return key
    end
  end
end

-- After an answer: ignore the rest of a fast key sequence, so it doesn't skip the result
local function drain()
  vim.wait(300)
  while vim.fn.getchar(0) ~= 0 do
  end
end

local function also(card, skip)
  local row = {}
  for i, a in ipairs(answers(card)) do
    if i ~= skip then
      row[#row + 1] = { #row == 0 and "   albo: " or ", ", "PvimTrainerDim" }
      row[#row + 1] = { T.pretty(a), "PvimTrainerKey" }
    end
  end
  return row
end

local function question_rows(card, n, total, typed, score)
  return {
    {
      { " " .. card.cat, "PvimTrainerDim" },
      { ("   %d/%d"):format(n, total), "PvimTrainerDim" },
      { ("   ✔ %d"):format(score.ok), "PvimTrainerOk" },
      { ("  ✘ %d"):format(score.bad), "PvimTrainerBad" },
    },
    "",
    T.md(" " .. card.q, "PvimTrainerTitle"),
    "",
    {
      { " ›  ", "PvimTrainerKey" },
      #typed > 0 and { T.pretty(typed), "PvimTrainerKey" } or { "naciśnij klawisze…", "PvimTrainerDim" },
    },
    "",
    { { " Enter", "PvimTrainerKey" }, { " nie wiem    ", "PvimTrainerDim" }, { "Ctrl+C", "PvimTrainerKey" }, { " koniec", "PvimTrainerDim" } },
  }
end

local function result_rows(card, ok, typed)
  local main = { " " .. T.pretty(answers(card)[1]), "PvimTrainerKey" }
  local rows = { "", T.md(" " .. card.q, "PvimTrainerTitle"), "" }
  if ok then
    local head = { { " ✔ Dobrze!", "PvimTrainerOk" }, main }
    vim.list_extend(head, also(card, 1))
    rows[#rows + 1] = head
  else
    rows[#rows + 1] = {
      { " ✘ ", "PvimTrainerBad" },
      { #typed > 0 and ("Twoje: " .. T.pretty(typed)) or "Nie szkodzi, zapamiętaj:", "PvimTrainerBad" },
    }
    local right = { { "   poprawnie:", "PvimTrainerDim" }, main }
    vim.list_extend(right, also(card, 1))
    rows[#rows + 1] = right
  end
  if card.note then
    rows[#rows + 1] = T.md("   " .. card.note, "PvimTrainerDim")
  end
  rows[#rows + 1] = ""
  rows[#rows + 1] = {
    { " dowolny klawisz", "PvimTrainerKey" },
    { " dalej    ", "PvimTrainerDim" },
    { "Esc", "PvimTrainerKey" },
    { " koniec", "PvimTrainerDim" },
  }
  return rows
end

local function summary_rows(score, missed, cat_id)
  local c = M.counts(cat_id)
  local rows = {
    "",
    { { " Koniec!   ", "PvimTrainerTitle" }, { ("✔ %d"):format(score.ok), "PvimTrainerOk" }, { ("   ✘ %d"):format(score.bad), "PvimTrainerBad" } },
    "",
  }
  if #missed > 0 then
    rows[#rows + 1] = { { " Do powtórki:", "PvimTrainerDim" } }
    for _, card in ipairs(missed) do
      rows[#rows + 1] = { { ("   %-14s "):format(T.pretty(answers(card)[1])), "PvimTrainerKey" }, { (card.q:gsub("`", "")) } }
    end
    rows[#rows + 1] = ""
  end
  rows[#rows + 1] = {
    { (" Opanowane: %d z %d pytań"):format(c.mastered, c.total), "PvimTrainerStar" },
    { "   (poprawnie kilka sesji z rzędu)", "PvimTrainerDim" },
  }
  rows[#rows + 1] = ""
  rows[#rows + 1] = { { " dowolny klawisz", "PvimTrainerKey" }, { " zamknij", "PvimTrainerDim" } }
  return rows
end

---@param opts? {category?: string}
function M.start(opts)
  opts = opts or {}
  T.highlights()
  local st = T.state()
  st.session = st.session + 1
  local queue = {}
  for _, card in ipairs(build_queue(opts.category)) do
    queue[#queue + 1] = { card = card }
  end
  if #queue == 0 then
    return vim.notify("Brak pytań w tym temacie", vim.log.levels.WARN, { title = "Quiz" })
  end

  local title = "Quiz skrótów"
  if opts.category then
    title = title .. ": " .. queue[1].card.cat
  end
  local ui = open_ui(title)
  local score, missed = { ok = 0, bad = 0 }, {}
  local ok_run, err = pcall(function()
    local i = 1
    while i <= #queue do
      local entry = queue[i]
      local typed, result = {}, nil
      while not result do
        draw(ui, question_rows(entry.card, i, #queue, typed, score))
        local key = getkey()
        if key == "<c-c>" then
          result = "quit"
        elseif key == "<cr>" then
          result = "bad"
        else
          typed[#typed + 1] = key
          result = match(entry.card, typed)
        end
      end
      if result == "quit" then
        break
      end
      local ok = result == "ok"
      if not entry.retry then
        record(entry.card, ok)
        T.save()
        score[ok and "ok" or "bad"] = score[ok and "ok" or "bad"] + 1
        if not ok then
          missed[#missed + 1] = entry.card
          table.insert(queue, math.min(i + 4, #queue + 1), { card = entry.card, retry = true })
        end
      end
      draw(ui, result_rows(entry.card, ok, typed))
      drain()
      local key = getkey()
      if key == "<esc>" or key == "q" or key == "<c-c>" then
        break
      end
      i = i + 1
    end
    if score.ok + score.bad > 0 then
      draw(ui, summary_rows(score, missed, opts.category))
      drain()
      getkey()
    end
  end)
  T.save()
  pcall(vim.api.nvim_win_close, ui.win, true)
  if not ok_run then
    vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Quiz" })
  end
end

return M
