-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- Overlay from dotfiles/omarchy/config/nvim. Only settings that differ from
-- LazyVim's defaults and that vim/vimrc explicitly asked for are repeated here.
-- LazyVim already sets number, relativenumber, ignorecase, smartcase, mouse,
-- clipboard, signcolumn, scrolloff, undofile and termguicolors.

-- Stated explicitly rather than relied on. These already match LazyVim's
-- defaults, but vim/vimrc sets the same pair for plain vim on the servers, and
-- having both sides declared keeps the alignment obvious instead of implicit.
-- This file is loaded before lazy.nvim starts, so it lands before any plugin
-- resolves a <leader> mapping.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- vimrc used 4-space indents; LazyVim defaults to 2.
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- vimrc kept these off; LazyVim leaves swap/backup on via undofile only.
opt.swapfile = false
opt.backup = false
opt.writebackup = false

opt.cursorline = true
opt.showmatch = true
