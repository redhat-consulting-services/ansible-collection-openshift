# mirror_images

An Ansible role to run oc-mirror workflows for registry-to-registry and registry-to-disk image mirroring.

## How to use

```yaml
---
- name: Mirror OpenShift images
  hosts: localhost
  gather_facts: false
  connection: local

  roles:
    - redhat_consulting_services.openshift.mirror_images
```

## Role Variables

```yaml
---
# base path used to store oc-mirror workspace, cache, credentials, and output
oc_mirror_base_path: /tmp/oc-mirror

mirror:
  # enable or disable mirroring execution
  enabled: true

  source:
    # source type: can be either `registry` or `disk`
    type: registry
    # optional TLS verification flag for source access
    tls_verify: true
    # source auth configuration in docker config.json format
    auth_config: |
      {
        "auths": {
          "registry.example.com": {
            "auth": "username:password"
          }
        }
      }

  destination:
    # destination type: can be either `registry` or `disk`
    type: registry
    # destination registry host when type is registry
    registry: registry.example.com
    # optional TLS verification flag for destination access
    tls_verify: true
    # destination auth configuration in docker config.json format
    auth_config: |
      {
        "auths": {
          "registry.example.com": {
            "auth": "username:password"
          }
        }
      }

image_sets:
  - # name: The name of the image set.
    name: openshift-additional
    # enabled: Set to true to include this image set in the mirroring process.
    enabled: true
    # destination: The destination path in the mirror registry or directory (optional).
    # If not specified, the default root path in the destination registry will be used.
    # oc-mirror by default uses already a pre-defined prefix for the destination path (e.g., "openshift" for OpenShift images).
    destination: ocp-additional
    # additional_images: A list of additional images to include in the mirroring process (optional).
    additional_images:
      - # name: The name of the additional image.
        name: registry.redhat.io/ubi9/ubi:latest
    # platform: The ocp platform information for the image set (optional).
    platform:
      # architectures: A list of architectures for the image set (optional).
      architectures:
        - amd64
      # channels: A list of channels for the image set (optional).
      channels:
        - # name: The name of the channel.
          name: stable
          # min_version: The minimum version for the channel (optional).
          min_version: 4.22
          # max_version: The maximum version for the channel (optional).
          max_version: 4.22
    # operators: A list of operators to include in the image set (optional).
    operators:
      - # catalog: The catalog image for the operator.
        catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
        # packages: A list of packages for the operator.
        packages:
          - # name: The name of the package.
            name: advanced-cluster-management
            # min_version: The minimum version for the channel (optional).
            min_version: 4.11
            # max_version: The maximum version for the channel (optional).
            max_version: 4.11
```
