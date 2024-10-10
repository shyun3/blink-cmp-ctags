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
                {
                    { "blink-cmp-ctags" },
                    { "blink.cmp.sources.buffer" },
                    { "blink.cmp.sources.path" },
                },
            },
        },
    },
},
```
