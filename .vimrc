set runtimepath+=$HOME/.vim_runtime

source $HOME/.vim_runtime/vimrcs/basic.vim
source $HOME/.vim_runtime/vimrcs/filetypes.vim
source $HOME/.vim_runtime/vimrcs/plugins_config.vim
source $HOME/.vim_runtime/vimrcs/extended.vim

try
source $HOME/.vim_runtime/my_configs.vim
catch
endtry

inoremap jj <ESC>
