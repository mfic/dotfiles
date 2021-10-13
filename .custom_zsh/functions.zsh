encodeb64 () {
    echo $1 | base64 | pbcopy
}

build-latex(){
    docker run -i --rm --name latex -v "$PWD":/usr/src/app -w /usr/src/app registry.gitlab.com/islandoftex/images/texlive:latest arara -v $1
}

rename-all-sequentially(){
    ls -v | cat -n | while read n f; do mv -n "${f}" "${1}-${n}.${2}"; done 
}

kubectl_delte_ns()
{
    echo "Enter Namespace you want to delete:"
    read NAMESPACE
    kubectl get namespace $NAMESPACE -o json > $NAMESPACE.json
    sed -i -e 's/"kubernetes"//' $NAMESPACE.json
    kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f ./$NAMESPACE.json
    rm -rf ./$NAMESPACE.json
    rm -rf ./$NAMESPACE.json-e
}
