<!---
Copyright (c) [2024] Fergal Somers
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->

# Context  <!-- omit from toc -->
This repo illustrates usage of [Operator Lifecycle Mangager](https://operator-framework.github.io/operator-controller/) (OLM) and [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) to install standard platform services via GitOps on a local [kind](https://kind.sigs.k8s.io/) cluster.

- OLM install taken originally from https://operator-framework.github.io/operator-controller/getting-started/olmv1_getting_started/
- OLMv1 catalog upgraded to 0.31.0
- built using kind - so that you can run kubernetes locally on your laptop.

What are standard platform service? These are the services that every 
Kubernetes clusters needs: 

- ArgoCD for GITOps
- Istio service mesh for secure communication within your cluster. 
- ArgoWorkflow for orchestration tasks
- ArgoRollouts for rollouts of services
- OPA Gateway for policy enforcement
- Prometheus monitoring stack for observability and alerting
- Istio configurations to access ArgoCD and Grafana directly from your laptop

The purpose of this is to illustrate that once you have a K8 cluster and ArgoCD installed, you can easily cookie-cutter a platform ready for developers to use. 

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
./kind-setup.sh
```

This can take 5-10 minutes - it is doing quite a lot: 


1. Create a kind cluster call `olm-sample`
2. Create a kubeconfig in olm-sample directory. 
3. Install the Operator Lifecycle Manager (OLMv1)
4. Install Istio service mesh
5. Install ArgoCD in `argocd` namespace. 
6. Install the `platform` ArgoCD project and applications - see [boot-application](/boot-application/). ArgoCD will then take over loading all the various parts of the platform from [base](/base/) via GITOps. 

This base platform contains:

- OPA Gatekeeper 
- Kube-prometheus monitoring stack (includes Prometheus operator - i.e. not via OLM ) - https://github.com/prometheus-operator/kube-prometheus. This installs everything you need including Grafana and alertmanager (at least for dev). 

# To view ArgoCD UI

First get the password for the ArgoCD `admin` user, run:

```
> kubectl -n platform get secret platform-argocd-cluster \
    -o jsonpath='{.data.admin\.password}' | base64 -d
```

Then click on following URL in your browser : [http://localhost:8081/](http://localhost:8081)
- Istio has been configured to listen on the 8081 is a host port exposed by the Kind cluster. 


Alternatively, you can use kubectl to port-forward directly to the grafana service, run :

```
> nohup kubectl port-forward -n platform service/platform-argocd-server 8080:80 &
```

and then click on following URL in your browser : http://localhost:8080/


# To view Grafana

Simply click on following URL in your browser : [http://127.0.0.1:8081/](http://127.0.0.1:8081)

- Use the default grafana password admin/admin - you are prompted to change this on login.

Alternatively,  you can use kubectl to port-forward directly to the grafana service, run : 
```
> nohup kubectl port-forward -n monitoring service/grafana 3000 &
```

and then on following URL in your browser : http://localhost:3000/


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

- Expose services via Istio and Gateway


# Notes

OLM has issues (v1 vs ArgoCD)

OLMv1 currently going under a transtion to v1 
- ArgoCD not yet with the program (still mentions subscriptions as a means to control cluster-scoped behaviour). 
- Have switched to manual install of ArgoCD)

Installing prometheus via OLM worked, but the kube-prometheus also installs an operator and this seems to have less problem (so switched to the kube-prometheus version). 

Installing kube-prometheus community setup. 

Istio gateways match on hostnames, and we have bound ArgoCD and Grafana virtual services to `localhost` and `127.0.0.1` to allow them to both be served. A little hack-y admittedly but it works for laptop based access. Obviously a real setup would have proper DNS sub-domains. 