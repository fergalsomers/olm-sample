# olm-sample

This repo tests some configuations of Operator Lifecycle Mangager


- install taken originally from https://operator-framework.github.io/operator-controller/getting-started/olmv1_getting_started/
- catalog ^^^ upgraded to 0.31.0
- argocd operator installed by default
- basic argocd installation also installed (allowing you to move to argocd installation)


# To view catalog

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


# hack tools to interact with catalog service

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


# To Do

- integrate with Istio (turn off TLS in ArgoCD)
