# bootstrap_gitops

An Ansible role to install and configure OpenShift GitOps (Argo CD), including optional App of Apps bootstrap and repository registration.

## How to use

```yaml
---
- name: Bootstrap OpenShift GitOps
  hosts: localhost
  gather_facts: false
  connection: local

  roles:
    - redhat_consulting_services.openshift.bootstrap_gitops
```

## Role Variables

```yaml
---
argocd:
  placement:
    # node selector used for Argo CD workload placement
    node_selector:
      node-role.kubernetes.io/infra: ""
    # tolerations applied to Argo CD workload placement
    tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/infra
        operator: Exists
      - effect: NoExecute
        key: node-role.kubernetes.io/infra
        operator: Exists

  operator:
    # GitOps operator channel
    channel: gitops-1.21
    # install plan approval policy
    install_plan_approval: Automatic
    metadata:
      name: openshift-gitops-operator
      namespace: openshift-gitops-operator
    subscription:
      name: openshift-gitops-operator
      source: redhat-operators
      source_namespace: openshift-marketplace
      # optional CSV pinning (empty to use latest from channel)
      starting_csv: openshift-gitops-operators.v1.21.4

  instance:
    # Argo CD instance name and namespace
    name: openshift-gitops
    namespace: openshift-gitops
    # host defines the ArgoCD server host address; if empty, a default will be generated
    # If using a custom host, ensure it is part of the cluster's *.apps domain.
    host: ""
    # enable high availability settings
    ha_enabled: false
    # Argo CD RBAC policy.csv content
    rbac_policy: |
      g, system:cluster-admins, role:admin
      g, cluster-admins, role:admin
    # rbac_scopes: Optional, defaults to 'groups'
    rbac_scopes: groups

app_of_apps:
  # enable or disable the App of Apps application definition creation
  enabled: true
  # name of the App of Apps application
  name: app-of-apps
  # project for the App of Apps application
  project: default
  # source defines where to find the App of Apps manifests
  source:
    # repo URL for the App of Apps application
    repo: https://gitlab.example/openshift/openshift-configurations.git
    # target_revision for the App of Apps application (e.g., branch, tag, commit)
    target_revision: main
    # path within the repo for the App of Apps application
    path: overlays/app-of-apps
  sync_policy:
    automated:
      prune: true
      selfHeal: true
    sync_options:
      - Validate=false

# repositories is a list of git/helm/oci repositories to add to ArgoCD
repositories: []
  # - name: app-of-apps
  #   type: git                        # git, helm, or oci
  #   url: https://gitlab.example.com/openshift/openshift-configurations.git
  #   secret_type: repository          # repository, repo-creds, or repo-write-creds
  #   project: ""                      # restrict credential to an ArgoCD AppProject
  #   enableOCI: false                 # set true for OCI-hosted Helm charts (type: helm)
  #   authentication:
  #     username: ""
  #     password: ""
  #     private_key: ""                # SSH private key (git only)
  #     github:                        # GitHub App authentication (git only)
  #       app_id: ""
  #       app_installation_id: ""
  #       private_key: ""
  #       enterprise_base_url: ""      # GitHub Enterprise API URL (optional)
  #     azure:                         # Azure Service Principal (git only)
  #       client_id: ""
  #       tenant_id: ""
  #       client_secret: ""
  #     gcp:                           # GCP Service Account (git only)
  #       service_account_key: ""
  #     tls_client_cert:               # Mutual TLS (helm/oci only)
  #       cert_data: ""
  #       cert_key: ""
  #   insecure: false
  #   forceHttpBasicAuth: false

# certificate authority bundle for repository trust
ca_bundle:
  # name of the ConfigMap to create for user CA bundle
  name: user-ca-bundle
  # the key within the config map that contains the CA bundle data
  ca_key: ca-bundle.crt
```

## Repository Configuration

### Source Types

| Type | `type` | `enableOCI` | Description |
| ---- | ------ | ----------- | ----------- |
| Git | `git` | — | Git repository via HTTPS or SSH |
| Helm | `helm` | `false` | Traditional HTTP(S) Helm repository |
| OCI Helm | `helm` | `true` | Helm chart stored in an OCI registry |
| OCI | `oci` | — | Generic OCI artifact |

### Credential Scope (`secret_type`)

| Value | Description |
| ----- | ----------- |
| `repository` | Credentials for a single, specific repository (default) |
| `repo-creds` | Reusable credential template matched by URL prefix |
| `repo-write-creds` | Git write credentials (e.g. for Source Hydrator) |

Use `repo-creds` when multiple repositories share the same credentials to avoid duplication. Use `repo-write-creds` to separate write access from normal read credentials.

### Project Scoping

Set `project` to restrict a credential to a specific Argo CD `AppProject`, providing tenant/team isolation.

### Authentication Mechanisms

| Mechanism | Applicable types | Configuration key |
| --------- | ---------------- | ----------------- |
| Username + password/token | git, helm, oci | `authentication.username` / `authentication.password` |
| SSH private key | git | `authentication.private_key` |
| GitHub App | git | `authentication.github` |
| Azure Service Principal | git | `authentication.azure` |
| GCP Service Account | git | `authentication.gcp` |
| TLS client certificate | helm, oci | `authentication.tls_client_cert` |

### Server Trust

Server trust (Custom CA, SSH known hosts) is configured separately from authentication:

- **Custom CA**: Configure via the `argocd-tls-certs-cm` ConfigMap for endpoints using internal PKI, private CA, or self-signed certificates.
- **SSH known hosts**: Configure via the `argocd-ssh-known-hosts-cm` ConfigMap for SSH server identity verification.
- **CA bundle**: This role creates a user CA bundle ConfigMap via `ca_bundle` (see above).

### Examples

#### Git HTTPS with reusable credentials

```yaml
repositories:
  - name: team-a-git-creds
    type: git
    url: https://git.example.com/team-a/
    secret_type: repo-creds
    authentication:
      username: deploy-token
      password: "{{ vault_git_token }}"
```

#### Git SSH

```yaml
repositories:
  - name: infra-repo
    type: git
    url: git@git.example.com:team-a/infrastructure.git
    authentication:
      private_key: "{{ vault_ssh_private_key }}"
```

#### GitHub App

```yaml
repositories:
  - name: github-org-creds
    type: git
    url: https://github.com/my-org/
    secret_type: repo-creds
    authentication:
      github:
        app_id: "12345"
        app_installation_id: "67890"
        private_key: "{{ vault_github_app_key }}"
```

#### GitHub App with GitHub Enterprise

```yaml
repositories:
  - name: ghe-org-creds
    type: git
    url: https://github.example.com/my-org/
    secret_type: repo-creds
    authentication:
      github:
        app_id: "12345"
        app_installation_id: "67890"
        private_key: "{{ vault_ghe_app_key }}"
        enterprise_base_url: https://github.example.com/api/v3
```

#### OCI-hosted Helm chart

```yaml
repositories:
  - name: oci-helm-registry
    type: helm
    url: registry.example.com
    enableOCI: true
    authentication:
      username: robot-account
      password: "{{ vault_registry_token }}"
```

#### Helm repository with mutual TLS

```yaml
repositories:
  - name: internal-helm
    type: helm
    url: https://helm.internal.example.com/
    authentication:
      tls_client_cert:
        cert_data: "{{ vault_client_cert }}"
        cert_key: "{{ vault_client_key }}"
```

#### Project-scoped credentials

```yaml
repositories:
  - name: team-b-creds
    type: git
    url: https://git.example.com/team-b/
    secret_type: repo-creds
    project: team-b
    authentication:
      username: deploy-token
      password: "{{ vault_team_b_token }}"
```
