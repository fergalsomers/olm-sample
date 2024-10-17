# Boot / Root platform application

Once a Kubernetes cluster has been booted and ArgoCD installed, then everything else can be installed via ArgoCD. 

We use the ArgoCD "App of Apps" pattern. 

- create a new `platform` ArgoCD AppProject
- create a new `platform` ArgoCD application - this is the root app that will load all the other apps under [base](/base/) directory. 