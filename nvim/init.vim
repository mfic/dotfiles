" Neovim configuration — sources shared vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" Find dotfiles dir: resolve symlink on Linux, search common paths on Windows
let s:dotfiles_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
if !filereadable(s:dotfiles_dir . '/vim/vimrc')
    for s:candidate in [expand('~/.dotfiles'), expand('~/dotfiles')]
        if filereadable(s:candidate . '/vim/vimrc')
            let s:dotfiles_dir = s:candidate
            break
        endif
    endfor
endif
execute 'source ' . s:dotfiles_dir . '/vim/vimrc'
