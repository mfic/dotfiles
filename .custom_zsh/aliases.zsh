# various aliases

GIT=$(which git);
CUST_ALIASES=~/.custom_aliases

alias config="$GIT --git-dir=$HOME/.cfg/ --work-tree=$HOME";

alias vi="vim";

alias latex-build='docker run -i --rm --name latex -v $PWD:/usr/src/app -w /usr/src/app registry.gitlab.com/islandoftex/images/texlive:latest arara -v';

alias rustscan='docker run -it --rm --name rustscan rustscan/rustscan:latest';
alias wpscan='docker run -it --rm wpscanteam/wpscan';

if [[ -f "$CUST_ALIASES" ]]; then
    source $CUST_ALIASES;
fi

