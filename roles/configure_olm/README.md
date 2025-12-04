# configure_olm

A role to configure the Operator Life Cycle Management of a disconnected OpenShift Cluster.

It does the following:

* Disable default catalogsources
* Deploy a custom catalogsource
* Deploy a ImageDigestMirrorSet for the GitOps Operator
* Checks and waits until the changes has rolled out

## Role Variables

```yaml
---
# Mirror registry configuration
mirror_registry: "mirrorregistry.example.com:8443"

# OpenShift Version
ocp_version: "4.18"

# OperatorHub management
manage_operator_hub: true
disable_default_operator_sources: true

# Operator marketplace configuration
operator_marketplace_namespace: "openshift-marketplace"
restart_operator_pods: true
wait_for_pod_ready: true
operator_pod_restart_timeout: 300

# Pod label selectors for catalog sources
operator_pod_label_selectors:
  - "olm.catalogSource"

# MachineConfigPool monitoring
monitor_mcp_updates: true
wait_for_mcp_completion: true
mcp_names:
  - "master"
  - "worker"
mcp_check_timeout: 1800  # 30 minutes
mcp_check_interval: 30   # 30 seconds
```

## Example Playbook

```yaml
---
- name: Configure OLM
  hosts: localhost
  gather_facts: false
  connection: local

  roles:
    - redhat_consulting_services.openshift.configure_olm
```
