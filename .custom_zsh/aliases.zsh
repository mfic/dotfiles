# various aliases
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

alias vi="vim"

alias latex-build="docker run -i --rm --name latex -v "$PWD":/usr/src/app -w /usr/src/app registry.gitlab.com/islandoftex/images/texlive:latest arara -v"

alias rustscan='docker run -it --rm --name rustscan rustscan/rustscan:latest'
