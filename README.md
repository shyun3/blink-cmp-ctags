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

(Optional) Change default options

```lua
opts = {
    sources = {
        providers = {
            [ ... ] -- Other providers.
            {
                "blink-cmp-ctags",
                name = "Ctags",
                fallback_for = { "LSP" },
                opts = {
                    tag_files = vim.fn.tagfiles(), -- List of tag files
                    cache = true,
                    include_kinds = { "f", "v", "c", "m", "t" }, -- Tag kinds to include
                    max_items = 500, -- Maximum number of completion items to return (Be careful with this, higher numbers tend to crash blink.cmp when you have very large tag files)
                }
            },
        },
    },
},
```
