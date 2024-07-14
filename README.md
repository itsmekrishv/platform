# platform

Step 1 -
Basic Infra setup:
- Install docker, bash, kind cli, kubectl cli, crossplane cli, yq, gcloud, awscli, azure cli.
- kind create cluster --config kind.yaml
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

##############
# Crossplane #
##############

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

Kubernetes incluster provider for Cross plane control plane. 

- Write your own package for composiotions (XR, XRDs) on Google, AWS and Azure.

- Create a secret gcp SA 
- Create Cloud provider config


-- Install ArgoCD and deploy Infrastructur

helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd/helm-values.yaml --wait

kubectl apply --filename argocd/apps.yaml


# Building Package for Crossplane
Step 1 up xpkg build
Step 2 up login -u saikrishnav 
Step 3 up repository create platform-k8s
Step 4 up repo list
Step 5 up xpkg push saikrishnav/platform-k8s:v0.1 -f platform-poc*.xpkg