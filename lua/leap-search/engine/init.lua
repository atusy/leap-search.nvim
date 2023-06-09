---@alias pos {[1]: integer, [2]: integer, [3]: integer, [4]: integer}
---@alias target {pos: pos, wininfo?: {bufnr: integer}}

---@param opts_engine Opts_engine
---@param opts_leap table
---@return target[]
local function _search(pat, opts_engine, opts_leap)
  if opts_engine.fn then
    return opts_engine.fn(pat, opts_engine, opts_leap)
  end
  return require("leap-search.engine." .. opts_engine.name).search(pat, opts_engine, opts_leap)
end

local function reverse(x)
  local rev = {}
  for i = #x, 1, -1 do
    table.insert(rev, x[i])
  end
  return rev
end

---@param pat string
---@param opts_match Opts_match
---@param opts_leap table
---@return target[]
local function search(pat, opts_match, opts_leap)
  -- if a single engine simply return matches
  if #opts_match.engines == 1 then
    local data = _search(pat, opts_match.engines[1], opts_leap)
    return opts_leap.backward and reverse(data) or data
  end

  -- if multiple engines, merge matches
  local data = {} ---@type target[]
  local dup = {} ---@type table<integer, table<integer, true>>
  for _, engine in pairs(opts_match.engines) do
    local ok, matches = pcall(_search, pat, engine, opts_leap)
    if ok then
      for _, m in pairs(matches) do
        local row, col = m.pos[1], m.pos[2]
        if not dup[row] then
          dup[row] = {}
        end
        if not dup[row][col] then
          table.insert(data, m)
          dup[row][col] = true
        end
      end
    end
  end

  -- sort matches so to sort labels
  table.sort(data, function(a, b)
    return (a.pos[1] == b.pos[1] and a.pos[2] < b.pos[2]) or (a.pos[1] < b.pos[1])
  end)

  -- return merged and sorted matches
  return opts_leap.backward and reverse(data) or data
end

return { search = search }
