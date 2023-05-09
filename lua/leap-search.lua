---@class matchopts

---@field ignorecase boolean?
---@field magic boolean?
---@field smartcase boolean?

---@param pat string
---@param opts matchopts?
---@return boolean
local function leap(pat, opts)
  -- search for leap targets
  local targets = require("leap-search.engine.vim.regex").search(pat, 0, opts or {})
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
