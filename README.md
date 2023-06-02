# leap-search.nvim

Leap onto a specified search pattern.

## Requirements

- [leap.nvim]

### Optional

- [leap-wide.nvim](https://github.com/atusy/leap-wide.nvim) for labelling on multi-width characters on nvim <= 0.9
- [repeat.vim](https://github.com/tpope/vim-repeat) for dot repeats

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

### f/t-motions

For dot-repeating, install [repeat.vim](https://github.com/tpope/vim-repeat).

``` lua
local function motion(offset, backward)
  local pat = vim.fn.getcharstr()
  require("leap-search").leap(pat, {
    engines = {
      { name = "string.find", ignorecase = false, plain = true, nlines = 1 },
      -- { name = "kensaku.query", nlines = 1 }, -- to search Japanese string with romaji with https://github.com/lambdalisue/kensaku.vim
    },
    prefix_label = false,
  }, {
    backward = backward,
  })
end

vim.keymap.set({ "n", "x", "o" }, "f", function()
  motion(0, false)
end)
vim.keymap.set({ "n", "x", "o" }, "F", function()
  motion(0, true)
end)
vim.keymap.set({ "n", "x", "o" }, "t", function()
  motion(-1, false)
end)
vim.keymap.set({ "n", "x", "o" }, "T", function()
  motion(1, true)
end)
```

![](https://user-images.githubusercontent.com/30277794/239579838-f8c57d99-04e6-4e47-a3ad-4231322cd782.gif)

[leap.nvim]: https://github.com/ggandor/leap.nvim
