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

---@alias matchopts {ignorecase: boolean?, magic: boolean?, smartcase: boolean?}

---@param pat string
---@param opts matchopts
local function flag(pat, opts)
  local o = {}
  for k, v in pairs(opts) do
    if v == nil then
      o[k] = vim.o[k]
    else
      o[k] = v
    end
  end
  if o.ic and o.sc and string.match(pat, "[A-Z]") then
    o.ic = false
  end
  local prefix = "" .. (o.ma and "\\m" or "") .. (o.ic and "\\c" or "")
  return prefix .. pat
end

---@alias pos {[1]: integer, [2]: integer}[]

---@param pat string
---@param win integer
---@param opts matchopts?
---@return {pos: {[1]: integer, [2]: integer}}[]
local function search(pat, win, opts)
  local ret = {}
  local matches = gmatch_win(vim.regex(flag(pat, opts or {})), win)
  for _, m in pairs(matches) do
    for _, col in pairs(m[2]) do
      table.insert(ret, { pos = { m[1] + 1, col[1] + 1, col[1] + 1 } })
    end
  end
  return ret
end

---@param pat string
---@param opts matchopts?
---@return boolean
local function leap(pat, opts)
  -- search for leap targets
  local targets = search(pat, 0, opts or {})
  if #targets == 0 then
    return false
  end

  -- prepare autocmd to be invoked on LeapEnter and removed subsequently
  local autocmd
  local function del()
    pcall(vim.api.nvim_del_autocmd, autocmd)
  end

  -- avoid hiding matched strings by placing labels before the matches
  autocmd = vim.api.nvim_create_autocmd("User", {
    pattern = "LeapEnter",
    once = true,
    callback = function()
      for _, t in pairs(require("leap").state.args.targets) do
        local p = t.pos[2]
        if p > 1 then
          t.pos[2] = p - 1
          t.offset = 1
        end
        -- t.pos[2] = t.pos[2] == 0 and 0 or (t.pos[2] - 1)
      end
      vim.api.nvim_create_autocmd("User", { pattern = "LeapLeave", callback = del })

      local ok, w = pcall(require, 'leap-wide')
      if ok then
        w.fix_labelling()
      end
    end,
  })

  -- leap!
  local ok = pcall(require("leap").leap, {
    targets = targets,
    target_windows = { vim.api.nvim_get_current_win() },
    action = function(t)
      local r, c = t.pos[1], t.pos[2] + (t.offset or 0)
      require('leap.jump')["jump-to!"]({r, c}, {
        winid = vim.api.nvim_get_current_win(),
        ["add_to_jumplist?"] = true,
        mode = "n",
        offset = 0,
        ["backward?"] = false,
        ["inclusive_op?"] = true,
      })
    end
  })

  if not ok then
    del() -- ensure deleting autocmd if leap() failed before invoking LeapLeave
  end

  return true
end

return { leap = leap }
