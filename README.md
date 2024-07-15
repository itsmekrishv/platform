# platform

Step 1 - Install Nix
nix-shell --run $SHELL
Basic Infra setup:
- Install docker, bash, kind cli, kubectl cli, crossplane cli, yq, gcloud, awscli, azure cli.
- kind create cluster --config kind.yaml
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

##############
# Crossplane #
##############

Kubernetes incluster provider for Cross plane control plane. 

- Write your own package for composiotions (XR, XRDs) on Google, AWS and Azure.

- Create a secret gcp SA 
kubectl create ns crossplane-system
kubectl --namespace crossplane-system \
    create secret generic aws-creds \
    --from-file creds=./aws-creds.conf



-- Install ArgoCD and deploy Infrastructur

helm repo add argo \
    https://argoproj.github.io/argo-helm

helm repo update

helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd/helm-values.yaml --wait

## ArgoCD Init
export PASS=$(kubectl \
    --namespace argocd \
    get secret argocd-initial-admin-secret \
    --output jsonpath="{.data.password}" \
    | base64 --decode)

argocd login \
    --insecure \
    --username admin \
    --password $PASS \
    --grpc-web \
    argocd.127.0.0.1.nip.io

argocd account update-password \
    --current-password $PASS \
    --new-password admin123

echo http://argocd.127.0.0.1.nip.io

kubectl create -f argocd/project.yaml

kubectl apply --filename argocd/apps.yaml

- Create Cloud provider config

# Building Package for Crossplane

Step 1 up login -u saikrishnav 
Step 2 up repository create platform-k8s
Step 3 up repo list
Step 4 VERSION_TAG=v0.0.1
Step 5 up xpkg build --name platform-k8s.xpkg && up xpkg push xpkg.upbound.io/saikrishnav/platform-k8s:${VERSION_TAG} -f platform-k8s.xpkg