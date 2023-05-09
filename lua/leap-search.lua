---@class Opts_match
---@field engine? "vim.regex"
---@field ignorecase? boolean
---@field magic? boolean
---@field smartcase? boolean
---@field hl_group? string
local opts_match_default = {
  engine = "vim.regex",
  hl_group = "Search"
}

---@param pat string
---@param opts_match Opts_match?
---@return boolean
local function leap(pat, opts_match)
  local o = vim.tbl_deep_extend("keep", opts_match or {}, opts_match_default)
  -- search for leap targets
  local targets = require("leap-search.engine." .. o.engine).search(pat, 0, o)
  if #targets == 0 then
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
        local b = (t.wininfo and t.wininfo[1].bufnr or 0)
        bufs[b] = true
        vim.api.nvim_buf_set_extmark(t.wininfo and t.wininfo[1].bufnr or 0, ns, t.pos[1] - 1, t.pos[2] - 1, {
          end_col = t.pos[3] - 1,
          hl_group = o.hl_group
        })
        local p = t.pos[2]
        if p > 1 then
          t.pos[2] = p - 1
          t.offset = 1
        end
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
