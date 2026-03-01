" Neovim configuration — sources shared vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
let s:dotfiles_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
execute 'source ' . s:dotfiles_dir . '/vim/vimrc'
