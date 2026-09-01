# add_nodes role CI tests

This directory contains scenario-based integration tests for the `add_nodes` role. The tests render `nodes-config.yaml` and `auth.json` locally and assert the generated content without calling `oc adm node-image create`.

## Strategy

| Layer | What is tested | How |
| --- | --- | --- |
| Template output | IPv4/IPv6 NMState host networking in `nodes-config.yaml` | Positive scenarios with structured expectations |
| Facts | Role facts (`manifest_folder`, `additional_node_count`, paths) | Positive scenarios |
| Credentials | `auth.json` from `pull_secret` | Positive scenarios |
| Out of scope | ISO generation via `oc adm node-image create` | Tests keep `generate_iso: false` in `base-vars.yaml` |

### Design principles

1. **Scenario isolation** — Each scenario has its own `vars.yaml` and output directory under `scenarios/<name>/output/`.
2. **Shared fixtures** — `common/base-vars.yaml` provides minimal valid defaults; scenarios override only what they need.
3. **Declarative expectations** — Scenarios define a `test_expectations` block; `common/verify-generated-configs.yaml` validates parsed YAML output.
4. **No golden files** — Assertions target structured values (DNS, routes, per-interface IP stacks) instead of full-file diffs.

## Running tests locally

```bash
roles/add_nodes/_tests/ci/run-tests.sh
```

Or from this directory:

```bash
cd roles/add_nodes/_tests/ci
./run-tests.sh
```

## Scenarios

| Scenario | Coverage |
| --- | --- |
| `vlan-ipv4` | Bond/VLAN IPv4 addressing on a single worker |
| `dual-stack-host-networking` | IPv6 DNS, routes, bond/VLAN dual-stack addresses |
| `interface-dual-stack` | Direct ethernet IPv4 + IPv6 on one interface |
| `bond-ipv4-dhcp` | Bond IPv4 DHCP when host `bonds` entries are omitted |
| `multiple-workers` | Three workers with VLAN IPv4 and `additional_node_count` fact |

## Adding a scenario

1. Create `scenarios/<scenario-name>/vars.yaml` with role variables and `test_expectations`.
2. Add the scenario name to `POSITIVE_SCENARIOS` in `run-tests.sh`.
3. Run `./run-tests.sh`.

### `test_expectations` structure

```yaml
test_expectations:
  facts:
    additional_node_count: 1
    manifest_folder: "{{ scenario_output_dir }}/manifests"
    credentials_folder: "{{ scenario_output_dir }}/credentials"
    iso_location: "{{ scenario_output_dir }}/agent.iso"
  nodes_config:
    cpu_architecture: amd64
    additional_ntp_sources: [0.pool.ntp.org]
    dns_resolvers: [192.168.50.1, 2001:db8::1]
    routes:
      - destination: 0.0.0.0/0
        gateway: 192.168.50.1
    interfaces:
      - name: bond0.100
        ipv4_enabled: true
        ipv4_dhcp: false
        ipv6_enabled: true
        ipv6_dhcp: false
        ipv4_addresses: [192.168.50.21]
        ipv6_addresses: [2001:db8::21]
        ipv4_prefix_lengths: [24]
        ipv6_prefix_lengths: [64]
  auth_json: '{"auths":{"example.com":{"auth":"dGVzdDo="}}}'
```

Interface expectations are validated against the **first host** in `nodes-config.yaml`.

## Legacy manual playbook

The `_tests/playbook.yaml` and `_tests/vars.yaml` at the parent `_tests` folder are legacy manual examples. Use `scenarios/` and `run-tests.sh` in this directory for automated verification.
