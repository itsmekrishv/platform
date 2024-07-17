set -x
export GCP_SA_PATH=$1

if [[ -z $1 ]]; then
    echo "Unable to find the gcs key"
    exit 1
fi

#nix-shell --run $SHELL

# Check if kind is installed
kubectl --context kind-kind get ns 2> /dev/null

# Install kind if not installed
if [[ $? != 0 ]] 
then
    kind create cluster --config kind.yaml
    kubectl apply \
        --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml --wait
fi


# Add Helm Repo
helm repo add crossplane-stable \
    https://charts.crossplane.io/stable

helm repo add argo \
    https://argoproj.github.io/argo-helm

helm repo add bitnami \
     https://charts.bitnami.com/bitnami

helm repo add backstage \
     https://backstage.github.io/charts

helm repo update

kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

ping -c4 google.com

# Install Crossplane
helm upgrade --install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system --create-namespace --wait

# Install ArgoCD
helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd/helm-values.yaml --wait

# Setup GCP Secret, ToDo Add AWS and Azure Creds
kubectl --namespace crossplane-system \
    create secret generic gcp-creds \
    --from-file creds=$GCP_SA_PATH

# Install Providers for Multi Cloud, Helm and Kubernetes incluster
kubectl apply -f ./crossplane/providers/

# Wait for the providers to be healthy
kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=300s

# Install Provider Configs for Multi Cloud ToDo add other cloud providers once secret is added.
kubectl apply -f ./crossplane/provider-configs/

# Install XRDs and Compistions to deploy Google Gke Cluster. ToDo - Add other cloud 
kubectl apply -f ./crossplane/xrds.yaml
kubectl apply -f ./crossplane/compositions.yaml

# Last steps
export PASS=$(kubectl \
    --namespace argocd \
    get secret argocd-initial-admin-secret \
    --output jsonpath="{.data.password}" \
    | base64 --decode)

kubectl port-forward -n argocd service/argocd-server 8080:443 &

argocd login \
    --insecure \
    --username admin \
    --password $PASS \
    --grpc-web \
    127.0.0.1:8080

argocd account update-password \
    --current-password $PASS \
    --new-password admin123

kubectl apply -f argocd/project.yaml

# Patch ArgoCD to accept the token key
kubectl patch -n argocd configmap argocd-cm --type merge -p '{"data":{"accounts.admin":"apiKey"}}'

exit 1
# Manual steps
# Ngrok setup
ngrok config add-authtoken <token>
ngrok http https://localhost:8080 # Run in seperate interactive window.
# Will get some end point

#kubectl apply --filename deploy-app.yaml
# kubectl -n cloud-infra apply -f cloud-claims/gke.yaml

