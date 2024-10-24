blink-cmp-ctags
===============

Adds support for ctags to [Saghen/blink.cmp](https://github.com/Saghen/blink.cmp).

Installation
------------

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
                -- Add the ctags provider
                ctags = {
                    name = "Ctags",
                    module = "blink-cmp-ctags",
                    fallback_for = { "lsp" },
                },
            },
            completion = {
                -- Add ctags to the list
                enabled_providers = { "lsp", "path", "snippets", "buffer", "ctags" },
            },
        },
    },
},
```

(Optional) Change default options

```lua
ctags = {
    name = "Ctags",
    module = "blink-cmp-ctags",
    fallback_for = { "lsp" },
    opts = {
        -- List of tag files
        tag_files = vim.fn.tagfiles(),

        -- Turn tagfile caching on or off
        cache = true,

        -- Tag kinds to include
        include_kinds = { "f", "v", "c", "m", "t" },

        -- Maximum number of completion items to return
        max_items = 500,
    }
},
```
