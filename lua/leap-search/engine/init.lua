---@param opts_engine Opts_engine
---@param opts_leap table
---@return {pos: {[1]: integer, [2]: integer, [3]: integer}}[]
local function _search(pat, opts_engine, opts_leap)
  if opts_engine.fn then
    return opts_engine.fn(pat, opts_engine, opts_leap)
  end
  return require("leap-search.engine." .. opts_engine.name).search(pat, opts_engine, opts_leap)
end

---@param pat string
---@param opts_match Opts_match
---@param opts_leap table
local function search(pat, opts_match, opts_leap)
  -- if a single engine simply return matches
  if #opts_match.engines == 1 then
    return _search(pat, opts_match.engines[1], opts_leap)
  end

  -- if multiple engines, return merged matches
  local data = {}
  for _, engine in pairs(opts_match.engines) do
    local ok, matches = pcall(_search, pat, engine, opts_leap)
    if ok then
      for _, m in pairs(matches) do
        local row, col = m.pos[1], m.pos[2]
        if not data[row] then
          data[row] = {}
        end
        if not data[row][col] then
          data[row][col] = m
        end
      end
    end
  end

  local ret = {}
  for _, poslist in pairs(data) do
    for _, pos in pairs(poslist) do
      table.insert(ret, pos)
    end
  end

  return ret
end

return { search = search }
