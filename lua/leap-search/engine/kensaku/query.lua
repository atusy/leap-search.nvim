---@class Opts_kensaku_query: Opts_vim_regex
---@field name string "kensaku.query"

---@param pat string
---@param opts_engine Opts_kensaku_query
---@param opts_leap table
local function search(pat, opts_engine, opts_leap)
  local query = vim.fn["kensaku#query"](pat)
  local ok, res = pcall(require("leap-search.engine.vim.regex").search, query, opts_engine, opts_leap)
  if ok then
    return res
  end
  if string.find(tostring(res), "Vim:E554: Syntax error in \\{...}", nil, true) then
    return require("leap-search.engine.vim.regex").search(
      query:gsub("\\{", "{"):gsub("\\}", "}"),
      opts_engine,
      opts_leap
    )
  end
  error(res)
end

return {
  search = search,
}
