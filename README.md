> This has been forked from a deprecated project.
> The official replacement now is [ctags-lsp.nvim](https://github.com/netmute/ctags-lsp.nvim).

blink-cmp-ctags
===============

Adds support for ctags to [Saghen/blink.cmp](https://github.com/Saghen/blink.cmp).

Installation
------------

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
    opts = {
        -- List of tag files
        tag_files = vim.fn.tagfiles(),

        -- Maximum number of completion items to return
        max_items = 500,
    }
},
```
