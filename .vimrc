set runtimepath+=/Users/mfic/.dotfiles/vim_runtime

source /Users/mfic/.dotfiles/vim_runtime/vimrcs/basic.vim
source /Users/mfic/.dotfiles/vim_runtime/vimrcs/filetypes.vim
source /Users/mfic/.dotfiles/vim_runtime/vimrcs/plugins_config.vim
source /Users/mfic/.dotfiles/vim_runtime/vimrcs/extended.vim

try
source /Users/mfic/.dotfiles/vim_runtime/my_configs.vim
catch
endtry

inoremap jj <ESC>
