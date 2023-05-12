local labels = {
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
}

local labels2 = {}
for _, v in pairs(labels) do
  labels2[v] = true
end

local getcharstr = vim.fn.getcharstr
local s = ""

local function clean()
  vim.fn.getcharstr = getcharstr
  s = ""
end

local function leap_interactive_core(fn, pat, opts_match, opts_leap)
  -- leap!
  local ok, res = pcall(fn, pat, opts_match, opts_leap)

  --recurse
  if ok and res and s ~= "" then
    vim.api.nvim_echo({ { pat } }, false, {})
    return leap_interactive_core(fn, pat .. s, opts_match, opts_leap)
  end

  return ok, res
end

local function leap_interactive(fn)
  -- use injection to avoid looped dependencies
  return function(_, opts_match, opts_leap)
    local _pat = getcharstr()
    vim.api.nvim_echo({ { _pat } }, false, {})
    local _opts_leap = vim.tbl_deep_extend("keep", opts_leap or {}, {
      action = function(t)
        if t.label == nil or labels2[t.label] then
          require("leap-search.action").jump(t)
          return
        end
      end,
      opts = { labels = labels },
    })

    vim.fn.getcharstr = function(...)
      s = getcharstr(...)
      return s
    end

    --leap interactively
    local ok, res = leap_interactive_core(fn, _pat, opts_match, _opts_leap)

    --finish
    clean()
    if ok then
      return s == ""
    end
    error(res)
  end
end

return leap_interactive
