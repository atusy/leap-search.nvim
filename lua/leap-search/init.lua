---@class Opts_user_engine
---@field name string
---@field fn fun(string, table, table): {pos: {[1]: integer, [2]: integer, [3]: integer}}[]

---@alias Opts_engine Opts_vim_regex | Opts_string_find | Opts_kensaku_query | Opts_user_engine

local function priority()
  local ok, res = pcall(function()
    return require("leap.highlight").priority.label
  end)
  if ok then
    return res
  end
  return nil
end

---@class Opts_match
---@field engines Opts_engine[]
---@field hl_group? string highlight group for matches (defaults to Search)
---@field priority? string highlight priority for hl_group (default to leap.highlight.priority.label)
---@field interactive? boolean defaults to false
---@field prefix_label? boolean defaults to true so to avoid hiding matches with labels
---@field experimental? table<string, any>
local opts_match_default = {
  engines = { { name = "vim.regex" } },
  hl_group = "Search",
  priority = priority(),
}

---@param pat string | fun(): string
---@param opts_match Opts_match?
---@param opts_leap table?
---@return boolean
local function leap_main(pat, opts_match, opts_leap)
  local _opts_match = vim.tbl_deep_extend("keep", opts_match or {}, opts_match_default)
  local _opts_leap = vim.tbl_deep_extend("keep", opts_leap or {}, { action = require("leap-search.action").jump })

  -- prepare autocmd to be invoked on LeapEnter and removed subsequently
  local ns = vim.api.nvim_create_namespace("")
  local bufs = {}
  local function del()
    for b, _ in pairs(bufs) do
      vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
    end
  end

  -- search for leap targets
  local targets
  _opts_leap.targets = function()
    local s = type(pat) == "string" and pat or pat()
    targets = require("leap-search.engine").search(s, _opts_match, _opts_leap)
    if #targets == 1 and _opts_match.experimental and _opts_match.experimental.autojump == false then
      table.insert(targets, targets[1])
      local labels = require("leap").state.args.opts.labels
      require("leap").state.args.opts.labels = { labels[1], labels[1] }
    end
    require("leap").state.args.targets = targets
    if _opts_match.prefix_label ~= false then
      for _, t in pairs(require("leap").state.args.targets) do
        local b = (t.wininfo and t.wininfo.bufnr or 0)
        bufs[b] = true
        vim.api.nvim_buf_set_extmark(b, ns, t.pos[1] - 1, t.pos[2] - 1, {
          end_col = t.pos[3] - 1,
          hl_group = _opts_match.hl_group,
          priority = _opts_match.priority,
        })
        local p = t.pos[2]
        if p > 1 then
          t.pos[2] = p - 1
          t.offset = 1
        end
      end
    end

    vim.api.nvim_create_autocmd("User", { pattern = "LeapLeave", callback = del })

    local ok, w = pcall(require, "leap-wide")
    if ok then
      w.fix_labelling()
    end

    return targets
  end

  -- leap!
  local ok, err = pcall(require("leap").leap, _opts_leap)

  if not ok then
    del() -- ensure deleting autocmd if leap() failed before invoking LeapLeave
    error(err)
  end

  return #targets > 0
end

---@param pat? string
---@param opts_match Opts_match?
---@param opts_leap table?
---@return boolean
local function leap(pat, opts_match, opts_leap)
  if pat == nil or (opts_match and opts_match.interactive) then
    return require("leap-search.interactive")(leap_main)(pat, opts_match, opts_leap)
  end
  return leap_main(pat, opts_match, opts_leap)
end

return { leap = leap }
