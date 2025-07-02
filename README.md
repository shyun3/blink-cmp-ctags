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

        -- (Optional) Language specific mapping of tag kinds to LSP kinds
        tag_kinds_map = {
            -- Language name according to ctags
            -- See `ctags --list-languages`
            C = {
                -- For kinds, see `ctags --list-kinds-full=<language>`
                e = vim.lsp.protocol.CompletionItemKind.EnumMember,
                f = vim.lsp.protocol.CompletionItemKind.Function,
                g = vim.lsp.protocol.CompletionItemKind.Enum,
                h = vim.lsp.protocol.CompletionItemKind.Module,
                m = vim.lsp.protocol.CompletionItemKind.Field,
                s = vim.lsp.protocol.CompletionItemKind.Struct,
                t = vim.lsp.protocol.CompletionItemKind.Reference,
                u = vim.lsp.protocol.CompletionItemKind.Class,
                v = vim.lsp.protocol.CompletionItemKind.Variable,
            }
        }
    }
},
```
