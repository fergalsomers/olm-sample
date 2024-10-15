#!/bin/sh

set -x

# Pre-requisites (see readme)

# Define some istio ports (k8 container port and K8 nodePort - note we expose the nodeports as hostports in Kind)
# This will allow you to access the ingress gateway via port 8080 (e.g. http://localhost:8080/productpage )

export ISTIO_HTTP_PORT=8081
export ISTIO_HTTP_NODE_PORT=31590
export ISTIO_HTTPS_PORT=8444
export ISTIO_HTTPS_NODE_PORT=31591
export ISTIO_STATUS_PORT=8222
export ISTIO_STATUS_NODE_PORT=31592

kind create cluster \
  --wait 120s \
  --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: olm-sample
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: $ISTIO_HTTP_NODE_PORT  # Istio HTTP
      hostPort: $ISTIO_HTTP_PORT
      protocol: TCP
    - containerPort: $ISTIO_HTTPS_NODE_PORT # Istio HTTPS/TLS
      hostPort: $ISTIO_HTTPS_PORT
      protocol: TCP
    - containerPort: $ISTIO_STATUS_NODE_PORT # Istio status port
      hostPort: $ISTIO_STATUS_PORT
      protocol: TCP      
  
EOF

# Install the OLM operator (cert-manager and olm)
./olm-install.sh

echo "olm installed"

# This assumes you have Istio installed
# echo "Installing Istio"

# rm -rf istio-profile.yaml

# envsubst < istio-profile-template.yaml > istio-profile.yaml 

# istioctl install -f istio-profile.yaml -y


# echo "Setting up default namespace for Istio"
# kubectl label namespace default istio-injection=enabled

# # echo "Installing CRD's"
# kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
#   { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" | kubectl apply -f -; }


# echo "Installing demo app" 
# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/platform/kube/bookinfo.yaml

# echo "Install the gateway"

# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/networking/bookinfo-gateway.yaml

# echo "Installing ArgoCD Operator extension"

# kubectl apply -f ./config/olm_v1alpha1_clusterextension.yaml

# echo "Installing ArgoCD" 

# kubectl wait --for=condition=Installed "clusterextensions/argocd" --timeout="60s"

# kubectl apply -k ./platform-argocd

# kubectl wait --for='jsonpath={.status.server}="Running"' argocd/platform-argocd -n platform --timeout="60s"

# echo "ArgoCD running"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for='jsonpath={.status.availableReplicas}'=1 deployment/argocd-server -n  argocd --timeout="60s"

echo "ArgoCD is running"

echo "Installing the boot application" 

kubectl apply -k boot-application

echo "Boot application has been configured" 