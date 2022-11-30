---
layout:     post
title:      Neovim Spaghetti - LSP Servers, Linters, Formatters, and Treesitter
date:       2022-11-28 13:20
type:       post
draft:      true
---

<p align="center">
<img  src="https://github.com/roobert/roobert.github.io/raw/master/images/Neovim-logo.svg.png"/>
</p>

## Abstract

To make the most of Neovim it's useful to understand the technologies it can leverage along with how the various plugins that manage these technologies relate to one another and can be configured. In this article we'll attempt to untangle the Neovim plugin spaghetti that turns Neovim into a more featureful modern editor.

This article is broken up into the following sections:

1. Understanding the Technologies
2. LSP Servers are Only Half the Picture
2. Neovim Configuration Goals
4. Neovim Plugins which Solve Problems
3. Lunarvim - An IDE Layer with Sane Defaults
4. Adding Support for New Programming Languages

## Understanding the Technologies

First lets understand the technologies that we want to leverage..

### LSP - the Language Server Protocol

The Langauge Server Protocol was introduced to improve editor performance. Prior to LSP
editors would have to execute binaries to do things like linting and formatting. With
the advent of the LSP editors can get real-time feedback to the editor from a process
which runs in the background.

NeoVIM added LSP support in version `0.5.0` and describes it as follows:
> LSP facilitates features like go-to-definition, find-references, hover, completion, rename, format, refactor, etc., using semantic whole-project analysis (unlike ctags).

For each filetype opened an LSP client will connect to an LSP server and depending on
the server, a number of features become available, for example:
* completion
* linting
* formatting
* hover-signatures
* diagnostics

### Treesitter

Treesitter builds an internal graph representation of your code which can be used by
plugins authors to write plugins and for better than normal syntax highlighting.

### Linters

Linters check code for common problems and provide hints on how to correct any detected
issues.

### Formatters

Formatters format code to conform to a specific coding style.

## LSP Servers are Only Half the Picture

Not all LSP servers support all features and so it can be necessary to fall-back to executing a program to perform some tasks, for example: linting, or formatting.

In practice this means it is can be necessary to separately configure your LSP client, formatter(s), and a linter(s) for every language that you wish to have these features for. This can become complicated since it involves using multiple plugins to handle overlapping areas of responsibility and even more so because the ecosystem can shift and change quite regularly due to how new everything is which can often result in a broken configuration.

Next, we'll look at one way to try and ease the pain of handling what ends up being a
fairly complex system.

## Neovim Configuration Goals

First, let's set-out some goals:

* Minimize the amount of configuration we have to maintain
* Ensure we have mechanisms to install and update everything
* Ensure keybindings are discoverable, logically grouped, and don't conflict
* Create a cheatsheet to remind us of stuff we dont use often or can help us whilst learning

## Neovim Plugins which Solve Problems

Next, lets understand how the core-plugin management and wiring works. To begin, we'll
need to understand what the core plugins are and how they relate to one-another:

* nvim-lspconfig - configs to connect the built-in lsp client to lsp servers
* nvim-lsp-installer - originally used to install lsp /servers/, now replaced by Mason.
* Mason - a plugin which can be used to install and manage LSP servers, DAP servers, linters, and formatters
* mason-lspconfig - This bridges the gap between nvim-lspconfig and mason - registering
  LSP configs with neovim so the LSP client can connect to the servers
* null-ls - allow hooking things into the LSP client - this is used to, for example,
  hook programmes that are not LSP servers into the LSP client such as formatters, linters, etc. that are not LSP servers themselves.
* mason-null-ls - automatically install formatters/linters to be used by null-ls

If the above doesn't make a lot of sense, don't worry. Instead of trying to manage all
this stuff ourselves we can lean on one of the available community maintained systems
that has all of these preconfigured and wired up...

## Lunarvim - An IDE Layer with Sane Defaults

LunarVim is described as "An IDE layer for Neovim with sane defaults. Completely free and community driven.". LunarVIM adds a good set of default plugins to NeoVIM with configurations that will suit most people, and more importantly, it comes with all the essentials pre-configured - but also allows customisation (enabling/disabling/configuration), and extension using additional plugins.

If you'd like to know a bit more about what Lunarvim includes, you can read the default plugin list which can be found [here](https://www.lunarvim.org/docs/plugins/core-plugins-list), along with a list of extra plugins [here](https://www.lunarvim.org/docs/plugins/extra-plugins), and also the default settings which can be found [here](https://github.com/LunarVim/LunarVim/blob/master/lua/lvim/config/settings.lua).

Start by installing Lunarvim following the instructions[here](https://www.lunarvim.org/docs/installation).

Next we'll create an alias that allows us to open up multiple files in tabs:

```
alias vi="lvim -p"
alias vim=vi
```

All of the plugins in the above section are included in Lunarvim, apart from `mason-null-ls`,
lets add it to `~/.config/lvim/config.lua`:

```lua
lvim.plugins = {
  -- automatically install all the formatters and linters specified by the following
  -- config options:
  -- * linters.setup
  -- * formatters.setup
  { "jayp0521/mason-null-ls.nvim",
    config = function()
      require "mason-null-ls".setup({
        automatic_installation = false,
        automatic_setup = true,
        ensure_installed = nil
      })
    end
  },
}
```

Lunarvim is an excellent base system but in-order to really have a good experience we
need to understand how to customize it, configure it, and extend it.

## Adding Support for New Programming Languages

Although we're going to leverage Lunarvim, it's still necessary to do some configuration
when we want to add support for a new language.

### Langauge Server Protocol Servers (LSPs)

TODO: how to see what the LSP supports

Available LSP servers [here](https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers).

Update `~/.config/lvim/config.lua` with a list of desired LSP Servers to install:
```
require("mason-lspconfig").setup({
  ensure_installed = {
    "awk_ls",
    "bashls",
    "cssls",
    "dockerls",
    "gopls",
    "gradle_ls",
    "grammarly",
    "graphql",
    "html",
    "jsonls",
    "tsserver",
    "sumneko_lua",
    "marksman",
    "pyright",
    "pylsp",
    "sqlls",
    "tailwindcss",
    "terraformls",
    "tflint",
    "vuels",
    "yamlls"
  }
})
```

It's also possible to use an interactive method:

```
# Show available language servers
LspInstall <filetype>
# -or- to browse and install supported plugins
Mason
```

To check the state of the LSP client:
```
# Inspect which formatters and linters are attached to the buffer
:LspInfo
# -or-
:LvimInfo
```

### Treesitter

To see a list of available languages:
```
TSInstallInfo
```

Add the list of languages you'd like to have treesitter support for in `~/.config/lvim/config.lua`:
```
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "go",
  "hcl",
}
```

Once updated, run `:PackerCompile` and restart the editor.

Or interactively:
```
TSInstall <filetype>
```

### Optional Formatter(s)

To see supported formatters, run: `NullLsInfo`.

Optionally configure additional formatters in `~/.config/lvim/config.lua`:

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

Once added here, run: `PackerCompile` and restart the editor. You can check that the
formatters have been installed by checking the `Installed` list in `:Mason`.

### Optional Linter(s)

To see supported linters (diagnostics), run: `NullLsInfo`.

Optionally configure additional linters in `~/.config/lvim/config.lua`:

```lua
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "flake8", filetypes = { "python" } },
  { command = "shellcheck", extra_args = { "--severity", "warning" }, },
  { command = "codespell", filetypes = { "javascript", "python" },
  },
}
```

Once added here, run: `PackerCompile` and restart the editor. You can check that the
formatters have been installed by checking the `Installed` list in `:Mason`.

## Conclusion

blah blah blah

Check out my config..

Check out my colorscheme..
