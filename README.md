# ansible-collection-openshift

A collection that bundles roles for the management of OpenShift clusters

## Roles

- **add_nodes**: A role to add nodes to an OpenShift cluster
- **bootstrap_cluster**: A role to bootstrap an OpenShift cluster
- **bootstrap_gitops**: A role to install and configure OpenShift GitOps on an OpenShift cluster
- **configure_nodes**: A role to label and/or taint nodes in an OpenShift cluster
- **mirror_images**: A role to mirror OpenShift Operators and container images to a private registry

## Execution Environment

This collection includes an Ansible Execution Environment (EE) that packages the collection with all its dependencies and OpenShift CLI tools for easy deployment and usage.

### Container Images

The execution environment images are automatically built and published to:

**GitHub Container Registry**: <https://ghcr.io/redhat-consulting-services/ee-openshift>

### Available Image Tags

Images are built for multiple OpenShift versions with the following tag format:

- **Timestamped tags**: `ghcr.io/redhat-consulting-services/ee-openshift:<repo-tag>-ocp-<openshift-version>-<timestamp>`
- **Latest tags**: `ghcr.io/redhat-consulting-services/ee-openshift:<repo-tag>-ocp-<openshift-version>-latest`

#### Currently Supported OpenShift Versions

- `4.17.41`
- `4.18.25`
- `4.19.15`

#### Example Tags

```text
ghcr.io/redhat-consulting-services/ee-openshift:v1.0.0-ocp-4.19.15-202407221430
ghcr.io/redhat-consulting-services/ee-openshift:v1.0.0-ocp-4.18.25-latest
ghcr.io/redhat-consulting-services/ee-openshift:dev-ocp-4.17.41-latest
```

### Automatic Builds

The execution environment is automatically built using GitHub Actions on:

- Push to `main` or `feat/execution-environment` branches
- Pull requests to `main`
- Manual workflow dispatch

### Adding New OpenShift Versions

To add support for new OpenShift versions, modify the matrix in `.github/workflows/build-ee.yaml`:

```yaml
strategy:
  fail-fast: false
  matrix:
    openshift_version:
      - "4.17.41"
      - "4.18.25"
      - "4.19.15"
      - "4.20.0"  # Add new versions here
```

### What's Included

Each execution environment includes:

- **Ansible Collection**: `redhat_consulting_services.openshift`
- **OpenShift CLI Tools**:
  - `oc` - OpenShift command-line interface
  - `openshift-install` - Cluster installation tool
  - `oc-mirror` - Registry mirroring tool
- **Python Dependencies**: All required Python packages
- **Ansible Collections**: `community.general`, `kubernetes.core`

### Manual Build

To build the execution environment locally:

```bash
ansible-builder build --context . -t my-ee:latest --build-arg OPENSHIFT_VERSION=4.19.15
```

### Usage

Use the execution environment with ansible-runner or in your automation platform:

```bash
podman run -it quay.io/redhatconsultingservices/ee-openshift:dev-ocp-4.19.15-latest ansible-playbook my-playbook.yml
```

## CI Flow

```mermaid
flowchart LR
    A[Commit]
    B[Push to branch]

    C[CI: Linting and Testing]
    C1{Linting and Testing successful?}

    D[Build Ansible collection]
    D1{Collection Build successful?}
    D2{Has been tagged and is main branch?}
    D3[Push to Galaxy]

    E[Merge to main branch]

    F[Run Execution Environment Build]
    F1{Execution Environment Build successful?}
    F2[Push to ghcr.io/quay.io/redhat-consultingservices/ee-openshift]

    G[Inform developers]

    A --> B --> C --> C1
    C1 -- Yes --> D --> D1
    D1 -- Yes --> D2
    D1 -- No --> A

    C1 -- No --> A

    D2 -- Yes --> D3
    D2 -- No --> E --> B

    D3 --> F --> F1
    F1 -- Yes --> F2
    F1 -- No --> G
```
