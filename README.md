# blink-cmp-ctags

Adds support for ctags to [Saghen/blink.cmp](https://github.com/Saghen/blink.cmp).

## Installation
Add your tag files to vim
```lua
vim.opt.tags:append(".git/tags", "tags")
```
Add provider in `lazy.nvim`
```lua
{
  "saghen/blink.cmp",
  dependencies = {
    "netmute/blink-cmp-ctags",
  },
  opts = {
    sources = {
      providers = {
        { "blink.cmp.sources.lsp", name = "LSP" },
        { "blink.cmp.sources.path", name = "Path", score_offset = 3 },
        { "blink.cmp.sources.snippets", name = "Snippets", score_offset = -3 },
        { "blink.cmp.sources.buffer", name = "Buffer", fallback_for = { "LSP" } },
        { "blink-cmp-ctags", name = "Ctags", fallback_for = { "LSP" } },
      },
    },
  },
},
```
