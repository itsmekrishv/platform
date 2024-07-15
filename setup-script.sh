set -x
export GCP_SA_PATH=$1
# nix-shell --run $SHELL

kind create cluster --config kind.yaml
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl create ns crossplane-system
kubectl --namespace crossplane-system \
    create secret generic gcp-creds \
    --from-file creds=$GCP_SA_PATH


helm repo add argo \
    https://argoproj.github.io/argo-helm

helm repo update

helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd/helm-values.yaml --wait

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

kubectl create -f argocd/project.yaml

kubectl apply --filename deploy-app.yaml