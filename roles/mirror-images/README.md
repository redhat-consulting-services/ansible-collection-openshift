# Mirror Images

An ansible role to mirror container images from one registry to another or to a local directory.

## Role Variables

```yaml
# oc_mirror_base_path is the base path where the workspace, cache, mirror, credentials and image-sets directories will be created.
oc_mirror_base_path: /path/to/mirror

mirror:
  # enabled: Set to true to enable the mirroring process. When set to false, the role will not perform any actions.
  enabled: false

  source:
    # type: The type of source for the images. Can be 'registry' or 'disk'.
    type: registry
    # auth_config: The authentication configuration for the source registry.
    auth_config: |
      {
        "auths": {
          "source-registry.example.com": {
            "auth": "base64-encoded-auth"
          }
        }
      }

  destination:
    # type: The type of destination for the images. Can be 'registry' or 'disk'.
    type: disk
    # registry: The destination registry URL if the type is 'registry'.
    registry: destination-registry.example.com
    # auth_config: The authentication configuration for the destination registry.
    auth_config: |
      {
        "auths": {
          "destination-registry.example.com": {
            "auth": "base64-encoded-auth"
          }
        }
      }

image_sets:
  - # name: The name of the image set.
    name: openshift-additional
    # enabled: Set to true to include this image set in the mirroring process.
    enabled: true
    # destination: The destination path in the mirror registry or directory.
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
          min_version: 4.11
          # max_version: The maximum version for the channel (optional).
          max_version: 4.11
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
