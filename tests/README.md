# Role tests

Offline integration tests for every role in this collection. Each configurable option is covered by at least one case under `tests/integration/<role>/cases/`.

## How it works

- Roles run on `localhost` with mocked `kubernetes.core` modules (`tests/collections/.../kubernetes/core`).
- CLI tools (`openshift-install`, `oc`, `oc-mirror`) are stubbed under `tests/mocks/bin`.
- File-generating roles (`bootstrap_cluster`, `add_nodes`, `mirror_images`) assert rendered manifests.
- Cluster-facing roles assert mock API calls and resulting resources.

## Run locally

```bash
make test                 # all roles
make test-bootstrap_cluster
./tests/run-tests.sh configure_olm bootstrap_gitops
```

Requires `ansible-core` >= 2.18 and network access once to install `ansible.utils` via Galaxy.

## Adding a case

1. Create `tests/integration/<role>/cases/NN_description.yml`
2. Provide `name`, `vars`, optional `seed_resources`, and `assertions`
3. Re-run `make test-<role>`
