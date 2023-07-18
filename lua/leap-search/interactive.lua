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
local user_input = ""

local function clean()
  vim.fn.getcharstr = getcharstr
  user_input = ""
end

local backspace = vim.api.nvim_replace_termcodes("<BS>", true, false, true)
local ctrl_v = vim.api.nvim_replace_termcodes("<C-V>", true, false, true)

local function getcharstr2(...)
  user_input = getcharstr(...)
  return user_input
end

local function generate_pattern(pat, opts_match)
  if opts_match.experimental then
    if opts_match.experimental.backspace and user_input == backspace then
      return string.sub(pat, 1, vim.regex(".$"):match_str(pat))
    end
    if opts_match.experimental.ctrl_v and user_input == ctrl_v then
      user_input = getcharstr()
    end
  end
  return pat .. user_input
end

local function leap_interactive_core(leap, pat, opts_match, opts_leap)
  -- leap!
  local function getpat()
    if pat == nil then
      pat = getcharstr()
    end
    vim.api.nvim_echo({ { pat } }, false, {})
    return pat
  end
  local ok, res = pcall(leap, getpat, opts_match, opts_leap)

  --recurse
  if ok and res and user_input ~= "" then
    return leap_interactive_core(leap, generate_pattern(pat, opts_match), opts_match, opts_leap)
  end

  return ok, res
end

local function leap_interactive(leap)
  -- use injection to avoid looped dependencies
  return function(pat, opts_match, opts_leap)
    local _opts_leap = vim.tbl_deep_extend("keep", opts_leap or {}, {
      action = function(t)
        if t.label == nil or labels2[t.label] then
          user_input = ""
          require("leap-search.action").jump(t)
          return
        end
      end,
      opts = { labels = labels },
    })

    vim.fn.getcharstr = getcharstr2

    --leap interactively
    local ok, res = leap_interactive_core(leap, pat, opts_match, _opts_leap)

    --finish
    clean()
    if ok then
      return user_input == ""
    end
    error(res)
  end
end

return leap_interactive
