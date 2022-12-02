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

To make the most of Neovim it's useful to understand the technologies it can leverage,
how the various plugins that manage these technologies relate to one another, and how
they can be installed and configured. In this article we'll attempt to untangle the
Neovim plugin spaghetti that turns Neovim into a more featureful modern editor.

This article is broken up into the following sections:

1. [Understanding the Technologies](#understanding-the-technologies)
2. [LSP Servers are Only Half the Picture](#lsp-servers-are-only-half-the-picture)
3. [Neovim Configuration Goals](#neovim-configuration-goals)
4. [Neovim Plugins which Solve Problems](#neovim-plugins-which-solve-problems)
5. [Lunarvim - An IDE Layer with Sane Defaults](#lunarvim---an-ide-layer-with-sane-defaults)
6. [Adding Support for New Programming Languages](#adding-support-for-new-programming-languages)
7. [Keeping Everything Up-To-Date](#keeping-everything-up-to-date)
8. [Conclusion](#conclusion)

## [Understanding the Technologies](#understanding-the-technologies)

First lets understand the technologies that we want to leverage..

### LSP - the Language Server Protocol

The Langauge Server Protocol was introduced to improve editor performance. Prior to LSP
editors would have to execute binaries to do things like linting and formatting. With
the advent of the LSP editors can get real-time feedback to the editor from a process
which runs in the background.

NeoVIM added LSP support in version `0.5.0` and describes it as follows:
> LSP facilitates features like go-to-definition, find-references, hover, completion,
> rename, format, refactor, etc., using semantic whole-project analysis (unlike ctags).

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

## [LSP Servers are Only Half the Picture](#lsp-servers-are-only-half-the-picture)

Not all LSP servers support all features and so it can be necessary to fall-back to
executing a program to perform some tasks, for example: linting, or formatting.

In practice this means it is can be necessary to separately configure your LSP client,
formatter(s), and a linter(s) for every language that you wish to have these features
for. This can become complicated since it involves using multiple plugins to handle
overlapping areas of responsibility and even more so because the ecosystem can shift and
change quite regularly due to how new everything is, which can often result in a broken
configuration.

Next, we'll look at one way to try and ease the pain of handling what ends up being a
fairly complex system.

## [Neovim Configuration Goals](#neovim-configuration-goals)

First, let's set-out some goals:

* Minimize the amount of configuration we have to maintain
* Ensure we have mechanisms to install and update everything

## [Neovim Plugins which Solve Problems](#neovim-plugins-which-solve-problems)

Next, lets understand how the core-plugin management and configuration works. To begin, we'll
need to understand what the core plugins are and how they relate to one-another:

* [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - configs to connect the built-in lsp client to lsp servers
* [williamboman/mason](https://github.com/williamboman/mason) - a plugin which can be used to install and manage LSP servers, DAP servers, linters, and formatters
* [williamboman/mason-lspconfig](https://github.com/williamboman/mason-lspconfig) - This bridges the gap between nvim-lspconfig and mason - registering
  LSP configs with neovim so the LSP client can connect to the servers
* [jose-elias-alvarez/null-ls](https://github.com/jose-elias-alvarez/null-ls) - allow hooking things into the LSP client - this is used to, for example,
  hook programmes that are not LSP servers into the LSP client such as formatters, linters, etc. that are not LSP servers themselves.
* [jayp0521/mason-null-ls](https://github.com/jayp0521/mason-null-ls) - automatically install formatters/linters to be used by null-ls

If the above doesn't make a lot of sense, don't worry. Instead of trying to manage all
this stuff ourselves we can lean on one of the available community maintained systems
that has all of these preconfigured and wired up...

## [Lunarvim - An IDE Layer with Sane Defaults](#lunarvim-an-ide-layer-with-sane-defaults)

LunarVim is described as "An IDE layer for Neovim with sane defaults. Completely free
and community driven.". LunarVIM adds a good set of default plugins to NeoVIM with
configurations that will suit most people, and more importantly, it comes with all the
essentials pre-configured - but also allows customisation
(enabling/disabling/configuration), and extension using additional plugins.

If you'd like to know a bit more about what Lunarvim includes, you can read the default plugin list which can be found [here](https://www.lunarvim.org/docs/plugins/core-plugins-list), along with a list of extra plugins [here](https://www.lunarvim.org/docs/plugins/extra-plugins), and also the default settings which can be found [here](https://github.com/LunarVim/LunarVim/blob/master/lua/lvim/config/settings.lua).

Start by installing Lunarvim following the instructions[here](https://www.lunarvim.org/docs/installation).

Next we'll create some aliases for convenience and that by default allows us to open up multiple files in tabs:

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
need to understand how to customize it, configure it, and extend it, read on to find out
how.

## [Adding Support for New Programming Languages](#adding-support-for-new-programming-languages)

Although we're going to leverage Lunarvim, it's still necessary to do some configuration
when we want to add support for a new language. The next sections explain how to add
language support to the various different systems Neovim utilises to add language
functions to the editor.

### Langauge Server Protocol Servers (LSPs)

To see a list of available LSP servers, run `:help lspconfig-all`.

Update `~/.config/lvim/config.lua` with a list of desired LSP Servers to install:
```lua
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
:LspInstall <filetype>
# -or- to browse and install supported plugins
:Mason
```

To check the state of the LSP client:
```
# Inspect which formatters and linters are attached to the buffer
:LspInfo
# -or-
:LvimInfo
```

To see the features of the LSP server, see: `:lua print(vim.inspect(vim.lsp.protocol.make_client_capabilities()))`
```json
{
  callHierarchy = {
    dynamicRegistration = false
  },
  textDocument = {
    codeAction = {
      codeActionLiteralSupport = {
        codeActionKind = {
          valueSet = { "", "quickfix", "refactor", "refactor.extract", "refactor.inline", "refactor.rewrite", "source", "source.organizeImports" }
        }
      }
    }
  }
  ...
}
```

### Treesitter

To see a list of available languages:
```
:TSInstallInfo
```

Add the list of languages you'd like to have treesitter support for in `~/.config/lvim/config.lua`:
```lua
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
:TSInstall <filetype>
```

### Optional Formatter(s)

If there is no LSP server for the language, or the LSP server doesn't support a
formatter then it's possible to configure an external program to perform the formatting
via the null-ls plugin.

To see supported formatters, run: `:NullLsInfo`.

Optionally configure additional formatters in `~/.config/lvim/config.lua`:

```lua
-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  { command = "isort", filetypes = { "python" } },
  { command = "shfmt", filetypes = { "sh" } },
  { command = "terraform_fmt", filtypes = { "terraform" } },
  { command = "prettier", filetypes = { "typescript", "typescriptreact" }, },
}
```

Once added here, run: `:PackerCompile` and restart the editor. You can check that the
formatters have been installed by checking the `Installed` list in `:Mason`.

### Optional Linter(s)

If there is no LSP server for the language, or the LSP server doesn't support a linter
then it's possible to configure an external program to perform the linting via the
null-ls plugin.

To see supported linters (diagnostics), run: `:NullLsInfo`.

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

Once added here, run: `:PackerCompile` and restart the editor. You can check that the
formatters have been installed by checking the `Installed` list in `:Mason`.

## [Keeping Everything Up-To-Date](#keeping-everything-up-to-date)

To update Lunarvim itself:
```
:LvimUpdate
```

To update Neovim plugins
```
:PackerSync
```

To update formatters/linters/LSPs, etc.:
```
# followed by "U" to Update All
:Mason
```

## [Conclusion](#conclusion)

Hopefully this article has helped explain how to establish a solid base system for
Neovim along with how to the core components work together along with how to extend it
to support new languages that you'd like to work with and keep everything up-to-date!

You can check out my Neovim/Lunarvim config [here](https://github.com/roobert/dotfiles/blob/master/.config/lvim/config.lua) and my theme [here](https://github.com/roobert/nightshift.vim).
