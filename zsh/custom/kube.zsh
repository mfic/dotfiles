# Set the default kube context if present
DEFAULT_KUBE_CONTEXTS="$HOME/.kube/config"
if test -f "${DEFAULT_KUBE_CONTEXTS}"
then
  export KUBECONFIG="$DEFAULT_KUBE_CONTEXTS"
fi

# Additional contexts should be in ~/.kube/k8s/
CUSTOM_KUBE_CONTEXTS="$HOME/.kube/k8s"

if [ -d ${CUSTOM_KUBE_CONTEXTS} ]; then
    for contextFile in ${CUSTOM_KUBE_CONTEXTS}/*.yml;
    do
        export KUBECONFIG="$contextFile:$KUBECONFIG"
    done
fi
