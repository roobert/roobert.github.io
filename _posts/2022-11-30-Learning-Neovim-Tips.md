---
layout:     post
title:      Tips on Learning Neovim
date:       2022-11-30 20:20
type:       post
draft:      true
---

<p align="center">
<img  src="https://github.com/roobert/roobert.github.io/raw/master/images/Neovim-logo.svg.png"/>
</p>

## Abstract

Here are a few tips for learning Neovim.

## Plugins

The main way to customise Neovim is with plugins, either build your own configuration or
a good idea to begin with is to use a pre-packaged collection such as [Lunarvim](https://github.com/lunarvim/lunarvim).

Also, see my article on
[extending Neovim](https://roobert.github.io/2022/11/28/Extending-Neovim/).

## Default Keybindings

First, find a cheatsheet for your keyboard layout from [here](https://github.com/mattmc3/neovim-cheatsheet).

It's not critical to learn all the keybindings immediately, however, it is a good idea
to try and learn movement with `hjkl`.

Keep a copy of the keyboard cheatsheet handy for reference.

## Vim Tutor

Run `:Tutor` to go through a set of lessons that'll introduce you to the most common
features of Neovim.

## Discoverability with the Which-Key Plugin

If not using Lunarvim, install the `which-key` plugin.

```
lvim.builtin.which_key.mappings["f"] = { "<CMD>Telescope buffers<CR>", "Buffer list" }
lvim.builtin.which_key.mappings["t"] = { "<CMD>TroubleToggle document_diagnostics<CR>", "Trouble" }
lvim.builtin.which_key.mappings["-"] = { "<Plug>(toggle-lsp-diag-vtext)", "Toggle Diagnostics" }
lvim.builtin.which_key.mappings["+"] = { "<CMD>Copilot toggle<CR>", "Toggle Copilot" }
```

## Improving with the Cheatsheet Plugin

The cheatsheet plugin (not to be confused with the keyboard shortcuts cheatsheet) is a
great way to keep and refer to notes and reminders that you can use to improve your Neovim
knowledge.

Install the plugin by updating `~/.config/lvim/config.lua`:
```
lvim.plugins = {
  -- place to store reminders and rarely used but useful stuff
  { 'sudormrfbin/cheatsheet.nvim',
    requires = {
      { 'nvim-telescope/telescope.nvim' },
      { 'nvim-lua/popup.nvim' },
      { 'nvim-lua/plenary.nvim' },
    },
    config = function()
      require('cheatsheet').setup {
        -- hide bundled cheatsheets to make our own notes more easy to reference
        bundled_cheatsheets = false,
        bundled_plugin_cheatsheets = false,
        include_only_installed_plugins = false,
        location = 'bottom',
        keys_label = 'Keys',
        description_label = 'Description',
        show_help = true,
      }
    end,
  },
}
```

Create a `~/.config/nvim/cheatsheet.txt` and symlink it if using Lunarvim so it's included
in the adjusted `runtimepath`:
```
ln -s ~/.config/nvim/cheatsheet.txt ~/.config/lvim/cheatsheet.txt
```

Update `~/.config/nvim/cheatsheet.txt`:
```
## movement
Left, down, up, right   | h j k l
Previous/next paragraph | { }
Next/previous block     | [ ]
Top/bottom of file      | gg G

## comment-management
Toggle comments         | <leader>-/

## search-and-replace
Search and Replace                       | /<pattern>
Disable highlight after search           | <leader>-h
Press * on a word (or visual selection), | *
  // represents selected string          | :%s//replace/gc
Delete "whatever" from every open buffer | bufdo exe ":%g/whatever/d" | w

## diagnostics
Open diagnostics (Trouble plugin) and witch buffers with ctrl-j/k | <leader>-t
Toggle inline diagnostics                                         | <leader>--
Next/previous diagnostics                                         | ]d [d

## introspection
Show help/hint  | <shift>-k
Goto definition | gd

## file-management
Open file explorer           | <leader>-e
Prev/next buffer             | <shift>-h <shift>-l
Close buffer                 | <leader>-c
Fuzzy switch between buffers | <leader>-f
```

Open the cheat sheet viewer by pressing `<leader>-?`, in Lunarvim `<leader>` is spacebar.

Once the cheatsheet is open you can edit it with `<ctrl>-e`.

## Quick Reference

### Operator, Text Object, Motion

### Completion

### Snippets

### Co-Pilot

### Go-To Definition/Implementation/Help

### Macros

### Copy / Paste

## Conclusion

blah blah blah

Check out my config..

Check out my colorscheme..
