# cluster_installation_check

An Ansible role to ensure the OpenShift cluster is healthy and ready for further configuration. This role performs various checks and validations on the cluster components. Usually this role is executed as part of a larger playbook that bootstraps and installs an OpenShift cluster.

## Role Variables

```yaml
# base_dir: Directory where the OpenShift installation files are located
# This is usually the directory where the install-config.yaml file is located.
# When executed as part of a larger playbook where the bootstrap_cluster role is used,
# this variable is automatically set to the correct path.
base_dir: ""

# kubeconfig_path: Path to the kubeconfig file for the cluster
# This is usually located at <base_dir>/auth/kubeconfig
# When executed as part of a larger playbook where the bootstrap_cluster role is used,
# this variable is automatically set to the correct path.
kubeconfig_path: ""

# bootstrap_log_level: Level of logging for bootstrap wait command
# Valid values are: debug, info, warn, error
# Default is info
bootstrap_log_level: info

# installation_log_level: Level of logging for installation wait command
# Valid values are: debug, info, warn, error
# Default is info
installation_log_level: info
```

## Role facts

When this role is executed, it will set the following facts automatically:

| Fact Name               | Description                                      |
|-------------------------|--------------------------------------------------|
| cluster_node_count      | The number of nodes in the OpenShift cluster.    |
