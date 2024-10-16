# Context  <!-- omit from toc -->
This repo illustrates usage of [Operator Lifecycle Mangager](https://operator-framework.github.io/operator-controller/) (OLM) and [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) to install standard services via GitOps
on a local [kind](https://kind.sigs.k8s.io/) cluster.

- OLM install taken originally from https://operator-framework.github.io/operator-controller/getting-started/olmv1_getting_started/
- OLMv1 catalog upgraded to 0.31.0
- built using kind - so that you can run kubernetes locally on your laptop.

Contents

- [Pre-requisites](#pre-requisites)
- [How to install](#how-to-install)
- [To view ArgoCD UI](#to-view-argocd-ui)
- [To view Grafana](#to-view-grafana)
- [To run queries against the OLM catalog](#to-run-queries-against-the-olm-catalog)
- [OLM Tools you will need to configure RBAC for an Operator (from OLM)](#olm-tools-you-will-need-to-configure-rbac-for-an-operator-from-olm)
- [To clean up](#to-clean-up)
- [To Do](#to-do)
- [Notes](#notes)


# Pre-requisites

1. Install [Docker](https://docs.docker.com/engine/install/)
1. Install [kind](https://kind.sigs.k8s.io/) - for mac "brew install kind"
1. Install [kubectl](https://kubernetes.io/docs/reference/kubectl/) - for mac "brew install kubectl"
1. Install [git](https://git-scm.com/) - git comes with Xcode on mac. 

# How to install

Clone the repo and 

```
git clone https://github.com/fergalsomers/olm-sample.git
cd olm-sample
./kind.sh
```

This will:

1. Create a kind cluster call `olm-sample`
1. Create a kubeconfig in olm-sample directory. 
1. Install the Operator Lifecycle Manager (OLMv1)
1. Install ArgoCD in `argocd` namespace. 

This ArgoCD will then start booting some default configurations:

- OPA Gatekeeper 
- Prometheus Operator (via OLM) 
- Kube-prometheus monitoring stack (via Prometheus operator) - https://github.com/prometheus-operator/kube-prometheus. This installs everything you need including Grafana and alertmanager (at least for dev). 

# To view ArgoCD UI

First get the password

```
kubectl -n platform get secret platform-argocd-cluster -o jsonpath='{.data.admin\.password}' | base64 -d
```

See https://argocd-operator.readthedocs.io/en/latest/usage/basics/


Next port-forward to argocd server

```
nohup kubectl port-forward -n platform service/platform-argocd-server 8001:80 &
```

Click on following URL in your browser : http://localhost:8001/applications


# To view Grafana

```
nohup kubectl port-forward -n monitoring service/grafana 3000 &
```

Click on following URL in your browser : http://localhost:3000/

Uses the default grafana password admin/admin - you are prompted to change this on login.


# To run queries against the OLM catalog

So that you can see what bundles are possible to install...

port forward to the service

```
kubectl port-forward -n olmv1-system service/catalogd-service  8443:443
```

and in another terminal

```
curl -k https://localhost:8443/catalogs/operatorhubio/all.json 
```

For more info on how to parse using JQ - see https://operator-framework.github.io/operator-controller/howto/catalog-queries/

E.g.:

```
curl -sk https://localhost:8443/catalogs/operatorhubio/all.json  > catalog.json | jq -s '.[] | select( .schema == "olm.package") | .name '

```

Get external-secrets versions

```
cat catalog.json |  jq -s '.[] | select( .schema == "olm.bundle" ) | select( .package == "external-secrets-operator") | .name'
```

# OLM Tools you will need to configure RBAC for an Operator (from OLM)

OperatorHub provides some scripts to interact and process catalog services  
- OperatorHub for security reasons requires all extensions to be installed using their own serivce account (least privilege). 
- It provides some tools to help create these service accounts and RBAC necessary (rather than hand-coding them) via processing the bundles in the catalog. 
- See https://github.com/operator-framework/operator-controller/tree/main
- NOTE: By default version of BASH in mac is old. You should use a newer version (e.g brew install bash) - then update your path. 

Setup hack tools

```
git clone https://github.com/operator-framework/operator-controller.git
cd operator-controller/hack/tools/catalogs
export KUBECONFIG=<replace with location of kubeconfig file to cluster running catalog server>
```

Download catalog 

```
export CATALOGD_SERVICE_NAME=catalogd-service
./download-catalog operatorhubio
```

Generate manifests for a specific bundle and version, .e.g 

```
./generate-manifests install argocd-operator 0.6.0 < operatorhubio-catalog.json
```

# To clean up

kind delete cluster --name=olm-sample

# To Do

- integrate with Istio (turn off TLS in ArgoCD
- investigate using istioctl docker image to configure istio (removes a pre-requisite)

# Notes

OLM has issues (v1 vs ArgoCD)

OLMv1 currently going under a transtion to v1 
- ArgoCD not yet with the program (still mentions subscriptions as a means to control cluster-scoped behaviour). 
- Have switched to manual install of ArgoCD)

Installing prometheus via OLM (seems to work)
Installing kube-prometheus community setup. 

