# configure_nodes

An Ansible role to apply labels and taints to selected OpenShift nodes.

## How to use

```yaml
---
- name: Configure OpenShift nodes
  hosts: localhost
  gather_facts: false
  connection: local

  roles:
    - redhat_consulting_services.openshift.configure_nodes
```

## Role Variables

```yaml
---
# node selection strategy used in Jinja selectattr tests (for example: search, match)
node_filter_type: "search"

# pattern applied to node names for selecting target nodes
node_filter_pattern: ""

# labels to apply to each selected node
node_labels: {}

# taints to apply to each selected node
node_taints: []

# kubeconfig path used for cluster API access
kubeconfig_path: "~/.kube/config"
```
