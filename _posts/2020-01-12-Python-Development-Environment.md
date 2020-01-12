---
draft:      true
layout:     post
title:      Python CLI Tool Development Quickstart
date:       2019-01-12 16:04
type:       post
---

# Python CLI Tool Development Quickstart

![xkcd](https://imgs.xkcd.com/comics/python_environment_2x.png)

## Overview

This will describe how the following:

* pyenv to handle python versions
* vim with black and pylint for syntax checking and linting
* pipx to install global tools
* poetry for handling project dependencies and project development environment
* dephell for converting poetry config to setup.py
* pipx for sandboxed project installation from git repo

TODO:
* dockerization of project
* using venv

## Key

* PyEnv
* Global Tools
* Vim
* * ALE
* * Black
* * PyLint
* Python Project
* * Dependencies
* * * Poetry
* * * DepHell
* * Project Template
* * Editing the Project
* * CLI Tool Execution
* * Remote Installation

## PyEnv

Avoid using your operating systems package manager to install python, instead download the pyenv shell scripts to manage a global (to your user) and local (to specific directories) version(s) of python:

* https://github.com/pyenv/pyenv

Configure pyenv:
```
# install pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv

# add these to your shells RC file, e.g: ~/.zshrc or ~/.bashrc
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# reload shell config
source ~/.zshrc
# or
source ~/.bashrc

# install python and configure 
pyenv install 3.7.4
pyenv global 3.7.4
```

## Global Tools

Use `pipx` to install tools you'll want to use globally. Pipx will install each tool into it's own virtual environment.

```
pip install pipx

# add the following to your shell rc file:
PATH=${HOME}/.local/bin:${PATH}
```

## Vim

### ALE

ALE is a framework for async syntax checking, install from: https://github.com/dense-analysis/ale

### Black

Black is "The uncompromising Python code formatter" - it has no configuration options and will format your code consistently and inline with the majority of public python projects.

Install a Black for global Python:
```
pipx install black
```

Install MattF's Black ftplugin:
```
mkdir -p ~/.vim/ftplugin
cat >> ~/.vim/ftplugin/python.vim <<EOF
setlocal autoread

silent let g:black_virtualenv = substitute(system('poetry env info -p'), '\n\+$', '', '')
silent let s:black_command = substitute(system('which black'), '\n\+$', '', '')

if g:black_virtualenv == ""
    echom 'Skipping black formatting, unable to find virtualenv'
elseif s:black_command == "black not found"
    echom 'Skipping black formatting, unable to find black command'
else
    autocmd! BufWritePre <buffer> call s:PythonAutoformat()
endif

function s:PythonAutoformat() abort
    let cursor_pos = getpos('.')
    execute ':%!black -q - 2>/dev/null'
    call cursor(cursor_pos[1], cursor_pos[2])
endfunction
EOF
```

### PyLint

Install pylint:
```
pipx install pylint
```

Configure pylint for vim: https://github.com/gryf/pylint-vim

## Python Project

### Dependencies

#### Poetry

Poetry is a
```
pipx install poetry

alias pvim="poetry run vim"
```

#### DepHell

DepHell can be used to convert the poetry config file into a standard `setup.py` file which is used by pip.
```
pipx install dephell
```

### Project Template

```
mkdir -p ~/git/pyproject
cd ~/git/pyproject
curl http://gitignore.io/api/python -o .gitignore
poetry init
poetry add -D black

# this 
cat >> pyproject.toml <<EOF

[tool.poetry.scripts]
pyproject-cli = 'myproject.some_lib:some_method'
EOF

cat >> pyproject.toml <<EOF

[tool.dephell.main]
from = {format = "poetry", path = "pyproject.toml"}
to = {format = "setuppy", path = "setup.py"}
EOF
```

### Editing the Project

Run vim with poetry to enable black:
```
poetry run vim
# or use previously defined alias:
pvim
```

### CLI Tool Execution

Once you've developed the app:
```
# install the app
poetry install

# run the cli tool
poetry run pyproject-cli
```

### Remote Installation

Once you've commited your code to github, you can install with:
```
pipx install pyproject --spec git+ssh://git@github.com/roobert/pyproject
```

# EOF

With thanks to [Matt](https://github.com/matthewfranglen)!

* xkcd cartoon: https://xkcd.com/1987/
