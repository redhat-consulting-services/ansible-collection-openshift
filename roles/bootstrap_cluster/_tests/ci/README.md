# bootstrap_cluster role CI tests

This directory contains scenario-based integration tests for the `bootstrap_cluster` role. The tests render `install-config.yaml` and `agent-config.yaml` locally and assert the generated content without calling `openshift-install`.

## Strategy

| Layer | What is tested | How |
| --- | --- | --- |
| Validation | Role input assertions (`assert.yaml`) | Negative scenarios that must fail |
| Template output | VIP handling and NMState host networking | Positive scenarios with structured expectations |
| Facts | Role facts (`base_dir`, node counts, paths) | Positive scenarios |
| Out of scope | ISO generation and `openshift-install` (including UserManaged cluster-manifests workaround) | Tests keep `generate_iso: false` in `base-vars.yaml` |

### Design principles

1. **Scenario isolation** — Each scenario has its own `vars.yaml` and output directory under `scenarios/<name>/output/`.
2. **Shared fixtures** — `common/base-vars.yaml` provides minimal valid defaults; scenarios override only what they need.
3. **Declarative expectations** — Scenarios define a `test_expectations` block; `common/verify-generated-configs.yaml` validates parsed YAML output.
4. **No golden files** — Assertions target structured values (VIP lists, DNS, routes, per-interface IP stacks) instead of full-file diffs.

## Running tests locally

```bash
roles/bootstrap_cluster/_tests/ci/run-tests.sh
```

Or from this directory:

```bash
cd roles/bootstrap_cluster/_tests/ci
./run-tests.sh
```

## Scenarios

### Positive

| Scenario | Coverage |
| --- | --- |
| `single-stack-ipv4` | String VIPs, bond/VLAN IPv4 addressing |
| `dual-stack-vips` | `api_vip` / `ingress_vip` lists (IPv4 + IPv6) |
| `single-ipv6-vip` | IPv6-only VIP strings |
| `dual-stack-host-networking` | IPv6 DNS, routes, bond/VLAN dual-stack addresses |
| `user-managed` | `lb_type: UserManaged` without VIPs |
| `interface-addresses` | Direct ethernet IPv4 on multiple masters |
| `interface-dual-stack` | Direct ethernet IPv4 + IPv6 on one interface |
| `no-workers` | Master-only cluster (`worker.hosts: []`) |
| `bond-ipv4-dhcp` | Bond IPv4 DHCP when host bond addresses are omitted |

### Negative

| Scenario | Expected failure |
| --- | --- |
| `invalid-user-managed-with-vips` | VIPs set with `UserManaged` load balancer |
| `invalid-missing-vips` | Keepalived LB without VIPs |
| `invalid-too-many-vips` | More than two VIP entries |

## Adding a scenario

1. Create `scenarios/<scenario-name>/vars.yaml` with role variables and `test_expectations`.
2. Add the scenario name to `POSITIVE_SCENARIOS` or `NEGATIVE_SCENARIOS` in `run-tests.sh`.
3. Run `./run-tests.sh`.

### `test_expectations` structure

```yaml
test_expectations:
  install_config:
    api_vips: [192.168.50.10]
    ingress_vips: [192.168.50.11]
    load_balancer_type: UserManaged   # optional
  facts:
    master_node_count: 1
    worker_node_count: 0
    total_node_count: 1
    cluster_domain: ocp4-test.ocp4.example.com
    base_dir: "{{ scenario_output_dir }}/ocp4-test"
    manifest_folder: "{{ scenario_output_dir }}/ocp4-test/manifests"
    kubeconfig_path: "{{ scenario_output_dir }}/ocp4-test/auth/kubeconfig"
    kubeadmin_password_path: "{{ scenario_output_dir }}/ocp4-test/auth/kubeadmin-password"
  agent_config:
    dns_resolvers: [192.168.50.1, 2001:db8::1]
    routes:
      - destination: 0.0.0.0/0
        gateway: 192.168.50.1
    interfaces:
      - name: bond0
        ipv4_enabled: true
        ipv4_dhcp: false
        ipv6_enabled: true
        ipv6_dhcp: false
        ipv4_addresses: [192.168.50.20]
        ipv6_addresses: [2001:db8::20]
        ipv4_prefix_lengths: [24]
        ipv6_prefix_lengths: [64]
```

Interface expectations are validated against the **first host** in `agent-config.yaml`.

## Legacy manual playbooks

The directories `generic/`, `fact-check/`, `interface-addresses/`, and `no-workers/` in the parent `_tests` folder are legacy manual examples. Use `scenarios/` and `run-tests.sh` in this directory for automated verification.
