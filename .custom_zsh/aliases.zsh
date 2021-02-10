# various aliases
alias vi="vim"

alias latex-build="docker run -i --rm --name latex -v "$PWD":/usr/src/app -w /usr/src/app registry.gitlab.com/islandoftex/images/texlive:latest arara -v"
