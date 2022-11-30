---
layout:     post
title:      Improving with Neovim
date:       2022-11-30 20:20
type:       post
draft:      true
---

<p align="center">
<img  src="https://github.com/roobert/roobert.github.io/raw/master/images/Neovim-logo.svg.png"/>
</p>

## Abstract

Two useful plugins which can be used to 

## Discoverability with the Which-Key Plugin

```
lvim.builtin.which_key.mappings["f"] = { "<CMD>Telescope buffers<CR>", "Buffer list" }
lvim.builtin.which_key.mappings["t"] = { "<CMD>TroubleToggle document_diagnostics<CR>", "Trouble" }
lvim.builtin.which_key.mappings["-"] = { "<Plug>(toggle-lsp-diag-vtext)", "Toggle Diagnostics" }
lvim.builtin.which_key.mappings["+"] = { "<CMD>Copilot toggle<CR>", "Toggle Copilot" }
```

## Improving with the Cheatsheet Plugin

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

## Conclusion

blah blah blah

Check out my config..

Check out my colorscheme..
