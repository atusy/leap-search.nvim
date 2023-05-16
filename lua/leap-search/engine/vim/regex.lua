---@class Opts_vim_regex
---@field name "vim.regex"
---@field ignorecase? boolean
---@field magic? boolean
---@field smartcase? boolean

---@alias colrange {[1]: integer, [2]: integer}

---@param re any
---@param str string
---@return colrange[]
local function gmatch_str(re, str)
  local ret = {}
  local s = str
  local base = 0
  while true do
    local beggining, ending = re:match_str(s)
    if beggining == nil then
      return ret
    end
    s = string.sub(s, ending + 1)
    table.insert(ret, { base + beggining, base + ending })
    base = base + ending
  end
end

---@param re any
---@param buffer integer
---@param start integer
---@param end_ integer
---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_lines(re, buffer, start, end_)
  local ret = {}
  for i, line in pairs(vim.api.nvim_buf_get_lines(buffer, start, end_, true)) do
    local matches = gmatch_str(re, line)
    if #matches > 0 then
      table.insert(ret, { start + i - 1, matches })
    end
  end
  return ret
end

---@param re any
---@param win integer
---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_win(re, win)
  local ret = {}
  vim.api.nvim_win_call(win, function()
    ret = gmatch_lines(re, vim.api.nvim_win_get_buf(win), vim.fn.getpos("w0")[2] - 1, vim.fn.getpos("w$")[2])
  end)
  return ret
end

---@param pat string
---@param opts_engine Opts_vim_regex
local function flag(pat, opts_engine)
  local o = {}
  for _, k in pairs({ "ignorecase", "magic", "smartcase" }) do
    local v = opts_engine[k]
    if v == nil then
      o[k] = vim.o[k]
    else
      o[k] = v
    end
  end
  if o.ignorecase and o.smartcase and string.match(pat, "[A-Z]") then
    o.ignorecase = false
  end
  local prefix = "" .. (o.magic and "\\m" or "\\M") .. (o.ignorecase and "\\c" or "\\C")
  return prefix .. pat
end

---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_forward(re)
  local curpos = vim.fn.getcurpos()
  local currow, curcol = curpos[2] - 1, curpos[3] - 1
  local match_curline = gmatch_lines(re, 0, currow, currow + 1)
  local match_nextlines = gmatch_lines(re, 0, currow + 1, vim.fn.getpos("w$")[2])
  local ret = {}
  for _, m in pairs(match_curline) do
    local filtered = {} ---@type colrange[]
    for _, col in pairs(m[2]) do
      if col[1] > curcol then
        table.insert(filtered, col)
      end
    end
    table.insert(ret, { currow, filtered })
  end
  for _, m in pairs(match_nextlines) do
    table.insert(ret, m)
  end
  return ret
end

---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_backward(re)
  local curpos = vim.fn.getcurpos()
  local currow, curcol = curpos[2] - 1, curpos[3] - 1
  local match_curline = gmatch_lines(re, 0, currow, currow + 1)
  local match_prevlines = gmatch_lines(re, 0, vim.fn.getpos("w0")[2] - 1, currow)
  local ret = {}
  for _, m in pairs(match_curline) do
    local filtered = {} ---@type colrange[]
    for _, col in pairs(m[2]) do
      if col[1] < curcol then
        table.insert(filtered, col)
      end
    end
    table.insert(ret, { currow, filtered })
  end
  for _, m in pairs(match_prevlines) do
    table.insert(ret, m)
  end
  return ret
end

---@param pat string
---@param opts_engine Opts_vim_regex
---@param opts_leap table
local function search(pat, opts_engine, opts_leap)
  if pat == "" then
    return {}
  end

  local ret = {} ---@type {pos: {[1]: integer, [2]: integer, [3]: integer}}[]
  local reg = vim.regex(flag(pat, opts_engine))

  -- search forward / backward in the current window
  if not opts_leap.target_windows then
    local matches = (opts_leap.backward and gmatch_backward or gmatch_forward)(reg)
    local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    for _, m in pairs(matches) do
      for _, col in pairs(m[2]) do
        table.insert(ret, {
          pos = { m[1] + 1, col[1] + 1, col[2] + 1 },
          wininfo = wininfo,
        })
      end
    end
    return ret
  end

  -- search in the target windows
  for _, w in pairs(opts_leap.target_windows) do
    local matches = gmatch_win(reg, w)
    local wininfo = vim.fn.getwininfo(w)[1]
    for _, m in pairs(matches) do
      for _, col in pairs(m[2]) do
        table.insert(ret, {
          pos = { m[1] + 1, col[1] + 1, col[2] + 1 },
          wininfo = wininfo,
        })
      end
    end
  end
  return ret
end

return { search = search }
