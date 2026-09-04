# configure_olm

An Ansible role to configure OLM on disconnected OpenShift clusters by setting custom CatalogSources and mirror-related configuration. This role strictly applies the OLM config for platform and OpenShift GitOps related configuration. All other OLM configurations must be managed separately.

## How to use

```yaml
---
- name: Configure OLM on disconnected cluster
  hosts: localhost
  gather_facts: false
  connection: local

  roles:
    - redhat_consulting_services.openshift.configure_olm
```

## Role Variables

```yaml
---
# Mirror registry configuration
registry:
  # The full hostname and port of your disconnected/private image mirror.
  url: "mirrorregistry.example.com:8443"
  # The repository path on the mirror where operator images are stored.
  # Will be used as the base for constructing the idms mirror registry urls for each operator (e.g., "my-operators").
  #
  # Example:
  # If your mirror registry is at "mirrorregistry.example.com:8443" and you store operator images under "my-operators", set this to "my-operators".
  # If your mirror registry does not use a repository path and images are stored directly under the registry (e.g., "mirrorregistry.example.com:8443/openshift-gitops-1/gitops-operator-bundle"), set this to an empty string "".
  repository: ""
  # The specific index image name (excluding tag/digest) used to create the CatalogSource.
  # This must include the repository path if your mirror uses one (e.g., "my-operators/catalog-index").
  index: "redhat/redhat-operator-index"

catalog_source:
  # OpenShift version tag appended to index image (for example 4.20)
  ocp_version: "4.20"
  # CatalogSource resource name
  name: "redhat-operators"

operator_hub:
  # manage OperatorHub object from this role
  manage: true
  # disable default operator sources when true
  disable_default_sources: true

olm:
  # namespace containing OLM marketplace resources
  marketplace_namespace: "openshift-marketplace"
  pods:
    # restart catalog pods after applying OLM configuration
    restart: true
    # wait for restarted pods to become Ready
    wait_for_ready: true
    # timeout in seconds when waiting for pod readiness
    restart_timeout: 300
    # label selectors used to identify catalog pods
    label_selectors:
      - "olm.catalogSource"

machine_config_pool:
  # monitor MCP status after IDMS/ITMS changes
  watch_updates: true
  # wait until targeted MCPs report Updated=True
  wait_for_completion: true
  # overall MCP wait timeout in seconds
  timeout: 1800
  # polling interval in seconds while waiting
  interval: 30
  # MCP names to watch
  pool_names:
    - master
    - worker
```
