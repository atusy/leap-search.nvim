# leap-search.nvim

Leap onto a specified search pattern.

## Requirements

- [leap.nvim]

### Optional

- [leap-wide.nvim](https://github.com/atusy/leap-wide.nvim)

## Usage

### Leap with last search pattern

``` lua
require("leap-search").leap(vim.fn.getreg("/"))
```

![](https://user-images.githubusercontent.com/30277794/239579105-f53a4eca-a060-4a93-adc7-bd361ea692d1.gif)

#### Keymaps to go to next or previous matches

``` lua
vim.keymap.set("n", "<Leader>n", function()
  local pat = vim.fn.getreg("/")
  local leapable = require("leap-search").leap(pat)
  if not leapable then
    vim.cnd("normal! n")
  end
end)
vim.keymap.set("n", "<Leader>N", function()
  local pat = vim.fn.getreg("/")
  local leapable = require("leap-search").leap(pat, {}, { backward = true })
  if not leapable then
    vim.cnd("normal! N")
  end
end)
```

### Interactively find match and jump to it

Inspired by [fuzzy-motion.vim](https://github.com/yuki-yano/fuzzy-motion.vim)

``` lua
require("leap-search").leap(
  nil,
  {
    engines = {
      { name = "string.find", plain = true, ignorecase = true },
      -- { name = "kensaku.query" }, -- to search Japanese string with romaji with https://github.com/lambdalisue/kensaku.vim
    },
  },
  { target_windows = { vim.api.nvim_get_current_win() } }
)
```

![](https://user-images.githubusercontent.com/30277794/239579838-f8c57d99-04e6-4e47-a3ad-4231322cd782.gif)

[leap.nvim]: https://github.com/ggandor/leap.nvim
