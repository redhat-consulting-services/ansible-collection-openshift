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
registry:
  # The full hostname and port of your disconnected/private image mirror.
  url: "mirrorregistry.example.com:8443"
  # The repository path on the mirror where operator images are stored.
  repository: "operators/redhat"
  # The specific index image name (excluding tag/digest) used to create the CatalogSource.
  index: "redhat-operator-index"

catalog_source:
  # The specific OpenShift version tag to use for the CatalogSource index image (e.g., 4.20).
  ocp_version: "4.20"
  # The name given to the CatalogSource resource deployed on the cluster.
  name: "redhat-operators"

# OperatorHub management
operator_hub:
  # Whether Ansible should manage the OperatorHub configuration (true/false).
  manage: true
  # Whether to disable all default/upstream operator sources (e.g., Red Hat, Certified) when applying configuration.
  disable_default_sources: true

# Operator marketplace configuration
olm:
  # The namespace where Operator Lifecycle Manager components and CatalogSources reside.
  marketplace_namespace: "openshift-marketplace"
  pods:
    # Whether to delete and restart the CatalogSource index pods after configuration changes.
    restart: true
    # Whether to wait for the restarted CatalogSource pods to enter the 'Ready' state.
    wait_for_ready: true
    # The maximum time (in seconds) to wait for a restarted CatalogSource pod to become ready.
    restart_timeout: 300
    # Pod label selectors for catalog sources
    label_selectors:
      # Standard label used by OLM for identifying CatalogSource index pods.
      - "olm.catalogSource"

# MachineConfigPool monitoring
machine_config_pool:
  # Whether to monitor the status of MachineConfigPools (MCPs) after applying MirrorSets (IDMS/ITMS).
  watch_updates: true
  # Whether to wait until the MCPs report 'Updated: True' (i.e., nodes have finished rebooting/reconfiguring).
  wait_for_completion: true
  # The maximum total time (in seconds) to wait for MCP completion (e.g., 30 minutes).
  timeout: 1800
  # The interval (in seconds) between checks for MCP status during the wait period.
  interval: 30
  # List of MCP names to monitor for updates (typically 'master' and 'worker').
  pool_names:
    - master
    - worker
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
