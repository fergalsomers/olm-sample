# opa-gatekeeper policies

This folder illustrates installing OPA-gatekeper community maintained policies, for example pod-security-policies. 

- https://open-policy-agent.github.io/gatekeeper-library/website/

They are organized into 2 argocd applications:
- policies templates
- constraints

Constraints are intended to be tailored to your use-case, I've included some take from the samples to illustrate. GIT clone the library repo and have a look at the samples as a a basis for configuration, e.g. 

```
git clone https://github.com/open-policy-agent/gatekeeper-library.git
```

