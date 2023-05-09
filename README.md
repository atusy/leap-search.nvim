# leap-search.nvim

Leap onto a specified search pattern.

## Requirements

- [leap.nvim]

### Optional

- [leap-wide.nvim](https://github.com/atusy/leap-wide.nvim)

## Usage

``` lua
-- leap within window if match is found, otherwise go to next or prev
vim.keymap.set("n", "<Space>n", function()
  local pat = vim.fn.getreg("/")
  local leapable = require("leap-search").leap(pat)
  if not leapable then
    return vim.fn.search(pat)
  end
end)
vim.keymap.set("n", "<Space>N", function()
  local pat = vim.fn.getreg("/")
  local leapable = require("leap-search").leap(pat, {}, { backward = true })
  if not leapable then
    return vim.fn.search(pat, "b")
  end
end)
```

[leap.nvim]: https://github.com/ggandor/leap.nvim
