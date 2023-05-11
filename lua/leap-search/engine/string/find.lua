---@class Opts_string_find
---@field name "string.find"
---@field plain? boolean

---@param str string
---@param pat string
---@param plain? boolean
---@return colrange[]
local function gmatch_str(pat, str, plain)
  local ret = {} ---@type colrange[]
  local init = 0
  for _ = 1,#str do
    local left, right = string.find(str, pat, init, plain)
    if left == nil then
      return ret
    end
    init = left + 1
    local colrange = {left - 1, right and right or left}
    table.insert(ret, colrange)
  end
  return ret
end

---@param pat string
---@param buffer integer
---@param start integer
---@param end_ integer
local function gmatch_lines(pat, buffer, start, end_, plain)
  local ret = {}
  for i, line in pairs(vim.api.nvim_buf_get_lines(buffer, start, end_, true)) do
    local matches = gmatch_str(pat, line, plain)
    vim.print(line, matches)
    if #matches > 0 then
      table.insert(ret, { start + i - 1, matches })
    end
  end
  return ret
end

---@param pat string
---@param win integer
---@param plain? boolean
---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_win(pat, win, plain)
  local ret = {}
  vim.api.nvim_win_call(win, function()
    ret = gmatch_lines(pat, vim.api.nvim_win_get_buf(win), vim.fn.getpos("w0")[2] - 1, vim.fn.getpos("w$")[2], plain)
  end)
  return ret
end

---@param pat string
---@param plain? boolean
---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_forward(pat, plain)
  local curpos = vim.fn.getcurpos()
  local currow, curcol = curpos[2] - 1, curpos[3] - 1
  local match_curline = gmatch_lines(pat, 0, currow, currow + 1, plain)
  local match_nextlines = gmatch_lines(pat, 0, currow + 1, vim.fn.getpos("w$")[2], plain)
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

---@param pat string
---@param plain? boolean
---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_backward(pat, plain)
  local curpos = vim.fn.getcurpos()
  local currow, curcol = curpos[2] - 1, curpos[3] - 1
  local match_curline = gmatch_lines(pat, 0, currow, currow + 1, plain)
  local match_prevlines = gmatch_lines(pat, 0, vim.fn.getpos("w0")[2] - 1, currow, plain)
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
---@param opts_engine Opts_string_find
---@param opts_leap table
local function search(pat, opts_engine, opts_leap)
  vim.print(pat, opts_engine)
  local ret = {} ---@type {pos: {[1]: integer, [2]: integer, [3]: integer}}[]

  -- search forward / backward in the current window
  if not opts_leap.target_windows then
    local matches = (opts_leap.backward and gmatch_backward or gmatch_forward)(pat, opts_engine.plain)
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
    local matches = gmatch_win(pat, w, opts_engine.plain)
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
