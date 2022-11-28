---
layout:     post
title:      Extending Neovim - LSP, DAP, Linters, Formatters, and Treesitter
date:       2022-11-28 13:20
type:       post
draft:      true
---

## Abstract

In order to make the most of Neovim it's useful to understand the technologies it can
leverage along with how the various plugins that manage these technologies relate to one
another and can be configured.

1. Understanding the Technologies
2. Neovim Configuration Goals
4. Neovim Plugins which Solve Problems
3. Lunarvim - An IDE Layer with Sane Defaults
4. Adding Support for New Programming Languages

## Understanding the Technologies

### LSP - the Language Server Protocol

The Langauge Server Protocol was introduced to improve editor performance.

NeoVIM added LSP support in whenever and describes it as follows:
> LSP facilitates features like go-to-definition, find-references, hover, completion, rename, format, refactor, etc., using semantic whole-project analysis (unlike ctags).

For each filetype opened an LSP client will connect to an LSP server and depending on
the server, a number of features become available, the most useful of which are probably:
* completion
* linting
* formatting
* hover-signatures

Somewhat confusingly, not all servers support all features and so sometimes it's
necessary to fall-back to executing a program to perform some feature (i.e: linting, or
formatting) for you.

In practice this means you may need to separately configure your LSP client, formatter(s), and a linter for every filetype that you wish to have these features for. This can be complicated to get right and in the fast-paced world of neovim means that your configuration can break often as things change so rapidly.

So, there is a solution - a community maintained set of configurations that handle most
of this for most stuff.

### DAP - the Debugger Adapter Protocol

> nvim-dap is a Debug Adapter Protocol client implementation for Neovim. nvim-dap allows you to:
> * Launch an application to debug
> * Attach to running applications and debug them
> * Set breakpoints and step through code
> * Inspect the state of the application

### Linters

Linters check code for common problems.

### Formatters

Formatters format code to conform to a specific style.

### Treesitter

Treesitter builds an internal graph representation of your code which can be used by
plugins authors to write plugins and for better than normal syntax highlighting.

## Neovim Configuration Goals

* Minimize the amount of configuration we have to maintain
* Ensure we have mechanisms to install and update everything
* Ensure keybindings are discoverable, logically grouped, and don't conflict
* Create a cheatsheet to remind us of stuff we dont use often or can help us whilst learning

### Neovim Plugins which Solve Problems

* nvim-lspconfig - configs to connect the built-in lsp client to lsp servers
* nvim-lsp-installer - originally used to install lsp /servers/, now replaced by Mason.
* Mason - a plugin which can be used to install and manage LSP servers, DAP servers, linters, and formatters
* mason-lspconfig - This bridges the gap between nvim-lspconfig and mason - registering
* mason-tool-installer - 
  LSP configs with neovim so the LSP client can connect to the servers
* null-ls - allow hooking things into the LSP client - this is used to, for example,
  hook programmes that are not LSP servers into the LSP client such as formatters, linters, etc. that are not LSP servers themselves.

If the above doesn't make a lot of sense, don't worry. Instead of trying to manage all
this stuff ourselves we can lean on one of the available community maintained systems
that has all of these preconfigured.

## Lunarvim - An IDE Layer with Sane Defaults

LunarVim is described as "An IDE layer for Neovim with sane defaults. Completely free and community driven.". LunarVIM adds a good set of default plugins to NeoVIM with configurations that will suit most people, and more importantly to me, it comes with all the essentials pre-configured but also allows customisation (enabling/disabling/configuration) and extension using additional plugins.

The default plugin list can be found [here](https://www.lunarvim.org/docs/plugins/core-plugins-list), along with a list of extra plugins [here](https://www.lunarvim.org/docs/plugins/extra-plugins).

Default vim settings: https://github.com/LunarVim/LunarVim/blob/master/lua/lvim/config/settings.lua

## Adding Support for New Programming Languages

Although we're going to leverage Lunarvim, it's still necessary to do some configuration
when we want to add support for a new language.

### Langauge Server Protocol Servers (LSPs)

```
# Show available language servers
LspInstall <filetype>
# -or- to browse supported plugins
Mason

# Inspect which formatters and linters are attached to the buffer
LspInfo
# -or-
LvimInfo
```

TODO: how to see what the LSP supports

### Debugger Adapter Protocol

TODO

### Treesitter

Ensure treesitter parser to ensure highlighting works

```
TSInstall <filetype>
# Show installed and available parsers
TSInstallInfo
```

### Optional Formatter(s)

Optionally configure formatter

```lua
-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  { command = "isort", filetypes = { "python" } },
  { command = "shfmt", filetypes = { "sh" } },
  { command = "terraform_fmt", filtypes = { "terraform" } },
  {
    command = "prettier",
    -- extra_args = { "--print-with", "100" },
    filetypes = { "typescript", "typescriptreact" },
  },
}

```

### Optional Linter(s)

```lua
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "flake8", filetypes = { "python" } },
  { command = "shellcheck", extra_args = { "--severity", "warning" }, },
  { command = "codespell", filetypes = { "javascript", "python" },
  },
}
```

## CheatSheet

### Movement

```
# Left, down, up, right
h
j
k
l
```

```
# Previous/next paragraph
{
}
```

```
# Next/previous block
[
]
```

```
# Top/bottom of file
gg
G
```


### Comment Management

```
# Toggle comments
<leader>-/
```

### Search and Replace

```
/<pattern>
```

```
# Disable highlight after search
<leader>-h
```

```
# press * on a word (or visual selection)
*
# double // represents selected string
:%s//replace/gc
```

```
# Delete "whatever" from every open buffer
bufdo exe ":%g/whatever/d" | w
```

### Diagnostics

```
# Open diagnostics (Trouble plugin)
# Switch buffers with ctrl-j/k
<leader>-t
```

```
# Toggle inline diagnostics
<leader>--
```

```
# Next/previous diagnostics
]d
[d
```

### Introspection

Show hint
```
<shift>-k
```

Goto definition
```
gd
```

### File Management

```
# Open file explorer
<leader>-e
```

```
# Prev/next buffer
<shift>-h
<shift>-l
```

```
# Close buffer
<leader>-c
```

```
# Fuzzy switch between buffers
<leader>-f 
```

### Completion

#### Functions, etc.

#### Snippets

### Cheatsheet

### Colorscheme

