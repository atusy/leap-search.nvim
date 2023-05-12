local M = {}

function M.jump(t)
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

return M
