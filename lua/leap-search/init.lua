---@class Opts_user_engine
---@field name string
---@field fn fun(string, table, table): {pos: {[1]: integer, [2]: integer, [3]: integer}}[]

---@alias Opts_engine Opts_vim_regex | Opts_string_find | Opts_kensaku_query | Opts_user_engine

---@class Opts_match
---@field engines Opts_engine[]
---@field hl_group? string defaults to Search
---@field interactive? boolean defaults to false
---@field prefix_label? boolean defaults to true so to avoid hiding matches with labels
local opts_match_default = {
  engines = { { name = "vim.regex" } },
  hl_group = "Search",
}

---@param pat string
---@param opts_match Opts_match?
---@param opts_leap table?
---@return boolean
local function leap_main(pat, opts_match, opts_leap)
  local _opts_match = vim.tbl_deep_extend("keep", opts_match or {}, opts_match_default)
  local _opts_leap = vim.tbl_deep_extend("keep", opts_leap or {}, { action = require("leap-search.action").jump })
  -- search for leap targets
  _opts_leap.targets = require("leap-search.engine").search(pat, _opts_match, _opts_leap)
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
      if _opts_match.prefix_label ~= false then
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
