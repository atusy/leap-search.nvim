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
---@param strict_indexing boolean
---@return {[1]: integer, [2]: colrange[]}[]
local function gmatch_lines(re, buffer, start, end_, strict_indexing)
  local ret = {}
  for i, line in pairs(vim.api.nvim_buf_get_lines(buffer, start, end_, strict_indexing)) do
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
    ret = gmatch_lines(re, vim.api.nvim_win_get_buf(win), vim.fn.getpos("w0")[2] - 1, vim.fn.getpos("w$")[2], true)
  end)
  return ret
end

---@param pat string
---@param opts_match Opts_match
local function flag(pat, opts_match)
  local o = {}
  for k, v in pairs({"ignorecase", "magic", "smartcase"}) do
    if v == nil then
      o[k] = vim.o[k]
    else
      o[k] = v
    end
  end
  if o.ic and o.sc and string.match(pat, "[A-Z]") then
    o.ic = false
  end
  local prefix = "" .. (o.ma and "\\m" or "\\M") .. (o.ic and "\\c" or "\\C")
  return prefix .. pat
end

---@param pat string
---@param win integer
---@param opts_match Opts_match?
local function search(pat, win, opts_match)
  local ret = {} ---@type {pos: {[1]: integer, [2]: integer, [3]: integer}}[]
  local matches = gmatch_win(vim.regex(flag(pat, opts_match or {})), win)
  for _, m in pairs(matches) do
    for _, col in pairs(m[2]) do
      table.insert(ret, { pos = { m[1] + 1, col[1] + 1, col[2] + 1 } })
    end
  end
  return ret
end

return { search = search }
