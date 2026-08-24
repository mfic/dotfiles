-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- Overlay from dotfiles/omarchy/config/nvim, carrying across the handful of
-- bindings from vim/vimrc that are worth keeping inside LazyVim.

local map = vim.keymap.set

-- vimrc: jj escapes insert mode.
map("i", "jj", "<Esc>", { desc = "Escape insert mode" })

-- vimrc: Ctrl+n toggles the file tree. vimrc used NERDTree; LazyVim ships
-- neo-tree (see lazyvim.json extras), so this drives neo-tree instead of
-- installing a second tree plugin to fight it for the same key.
map("n", "<C-n>", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })

-- vimrc: Escape clears search highlight. Mapped to <Esc> in normal mode only,
-- so it does not interfere with LazyVim's terminal or copy-mode handling.
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
