encodeb64 () {
    echo $1 | base64 | pbcopy
}

build-latex(){
    docker run -i --rm --name latex -v "$PWD":/usr/src/app -w /usr/src/app registry.gitlab.com/islandoftex/images/texlive:latest arara -v $1
}
