---@class Opts_kensaku_query: Opts_vim_regex
---@field name string "kensaku.query"

---A wrapper of kensaku#query
---
---kensaku#query considers spaces as split character.
---in order to include space as a search keyword, this function splits the input pattern by spaces,
---query with non space strings, and then concat them with spaces.
--[[
```vim
:echo kensaku#query("%")
" \m\%([%‰％]\|パーセント\)

:echo kensaku#query("% %")
" \m\%([%‰％]\|パーセント\)\%([%‰％]\|パーセント\)
```
]]
---@param pat string
---@return string
local function kensaku_query(pat)
  local str = pat
  local query = ""
  for _ = 1, #str do
    local left, right = string.find(str, " +", 0, false)
    if left == nil then
      return query .. vim.fn["kensaku#query"](str)
    end
    if left > 1 then
      query = query .. vim.fn["kensaku#query"](string.sub(str, 1, left - 1))
    end
    query = query .. string.sub(str, left, right)
    str = string.sub(str, right + 1)
  end
  return query
end

---@param pat string
---@param opts_engine Opts_kensaku_query
---@param opts_leap table
local function search(pat, opts_engine, opts_leap)
  if pat == " " then
    ---NOTE: special care avoids infinite waiting from somewhere...
    return require("leap-search.engine.string.find").search(" ", {
      name = "string.find",
      plain = true,
      nlines = opts_engine.nlines,
    }, opts_leap)
  end
  local query = kensaku_query(pat)
  return require("leap-search.engine.vim.regex").search(query, opts_engine, opts_leap)
end

return {
  search = search,
}
