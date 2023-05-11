---@class Opts_user_engine
---@field name string
---@field fn fun(string, table, table): {pos: {[1]: integer, [2]: integer, [3]: integer}}[]

---@alias Opts_engine Opts_vim_regex | Opts_user_engine

---@class Opts_match
---@field engines Opts_engine[]
---@field hl_group? string
local opts_match_default = {
  engines = { { name = "vim.regex" } },
  hl_group = "Search",
}

local function action(t)
  local r, c = t.pos[1], t.pos[2] + (t.offset or 0)
  require("leap.jump")["jump-to!"]({ r, c }, {
    winid = vim.api.nvim_get_current_win(),
    ["add_to_jumplist?"] = true,
    mode = "n",
    offset = 0,
    ["backward?"] = false,
    ["inclusive_op?"] = true,
  })
end

---@param opts_engine Opts_engine
---@param opts_leap table
---@return {pos: {[1]: integer, [2]: integer, [3]: integer}}[]
local function _search(pat, opts_engine, opts_leap)
  if opts_engine.fn then
    return opts_engine.fn(pat, opts_engine, opts_leap)
  end
  return require("leap-search.engine." .. opts_engine.name).search(pat, opts_engine, opts_leap)
end

---@param opts_match Opts_match
---@param opts_leap table
local function search(pat, opts_match, opts_leap)
  -- if a single engine simply return matches
  if #opts_match.engines == 1 then
    return _search(pat, opts_match.engines[1], opts_leap)
  end

  -- if multiple engines, return merged matches
  local data = {}
  for _, engine in pairs(opts_match.engines) do
    local ok, matches = pcall(_search, pat, engine, opts_leap)
    if ok then
      for _, m in pairs(matches) do
        local row, col = m.pos[1], m.pos[2]
        if not data[row] then
          data[row] = {}
        end
        if not data[row][col] then
          data[row][col] = m
        end
      end
    end
  end

  local ret = {}
  for _, poslist in pairs(data) do
    for _, pos in pairs(poslist) do
      table.insert(ret, pos)
    end
  end

  return ret
end

---@param pat string
---@param opts_match Opts_match?
---@param opts_leap table?
---@return boolean
local function leap(pat, opts_match, opts_leap)
  local _opts_match = vim.tbl_deep_extend("force", opts_match or {}, opts_match_default)
  local _opts_leap = vim.tbl_deep_extend("keep", opts_leap or {}, { action = action })
  -- search for leap targets
  _opts_leap.targets = search(pat, _opts_match, _opts_leap)
  if #_opts_leap.targets == 0 then
    return false
  end

  -- prepare autocmd to be invoked on LeapEnter and removed subsequently
  local autocmd
  local ns = vim.api.nvim_create_namespace("")
  local bufs = {}
  local function del()
    pcall(vim.api.nvim_del_autocmd, autocmd)
    for b, _ in pairs(bufs) do
      vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
    end
  end

  -- avoid hiding matched strings by placing labels before the matches
  autocmd = vim.api.nvim_create_autocmd("User", {
    pattern = "LeapEnter",
    once = true,
    callback = function()
      for _, t in pairs(require("leap").state.args.targets) do
        local b = (t.wininfo and t.wininfo.bufnr or 0)
        bufs[b] = true
        vim.api.nvim_buf_set_extmark(b, ns, t.pos[1] - 1, t.pos[2] - 1, {
          end_col = t.pos[3] - 1,
          hl_group = _opts_match.hl_group,
        })
        local p = t.pos[2]
        if p > 1 then
          t.pos[2] = p - 1
          t.offset = 1
        end
      end
      vim.api.nvim_create_autocmd("User", { pattern = "LeapLeave", callback = del })

      local ok, w = pcall(require, "leap-wide")
      if ok then
        w.fix_labelling()
      end
    end,
  })

  -- leap!
  local ok, err = pcall(require("leap").leap, _opts_leap)

  if not ok then
    del() -- ensure deleting autocmd if leap() failed before invoking LeapLeave
    error(err)
  end

  return true
end

return { leap = leap }
