# approve_nodes

An Ansible role to approve the additional worker nodes after adding them to an existing OpenShift cluster using agent-based node join artifacts.

The role approves pending certificate signing requests for the added nodes and waits for them to become ready and schedulable.

## Example Playbook

```yaml
- name: Approve New OpenShift Nodes
  hosts: localhost
  gather_facts: false
  become: false
  vars_files:
    - ./nodes_config.yaml

  roles:
    - redhat_consulting_services.openshift.approve_nodes
```

For a more detailed example, please refer to the `examples/dell_hardware/playbook-scaling.yaml` file in this collection.

## Role Variables

```yaml
# kubeconfig_path defines the path to the kubeconfig file used to monitor and approve nodes in the OpenShift cluster.
kubeconfig_path: ""

# the loaded node config must provide worker hosts with a `hostname` and at least one nested `ip` value, for example:
worker:
  hosts:
    - hostname: worker-0
      vlans:
        - addresses:
            - ip: 192.0.2.10
```

## Role facts

When this role is executed, it will set the following facts automatically:

| Fact Name               | Description                                      |
|-------------------------|--------------------------------------------------|
| cluster_node_count      | The number of nodes in the OpenShift cluster.    |
