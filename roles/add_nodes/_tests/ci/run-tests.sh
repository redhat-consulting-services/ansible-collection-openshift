#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${TESTS_DIR}/common"
SCENARIOS_DIR="${TESTS_DIR}/scenarios"

POSITIVE_SCENARIOS=(
  vlan-ipv4
  dual-stack-host-networking
  interface-dual-stack
  bond-ipv4-dhcp
  multiple-workers
)

run_positive_scenario() {
  local scenario="$1"
  local scenario_dir="${SCENARIOS_DIR}/${scenario}"
  local output_dir="${scenario_dir}/output"

  rm -rf "${output_dir}"
  mkdir -p "${output_dir}"

  echo "==> Running positive scenario: ${scenario}"
  cd "${COMMON_DIR}"
  if ! ansible-playbook run-scenario.yaml \
    -e "@${scenario_dir}/vars.yaml" \
    -e "scenario_name=${scenario}" \
    -e "scenario_output_dir=${output_dir}"; then
    echo "ERROR: positive scenario ${scenario} failed"
    return 1
  fi
}

main() {
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "ansible-playbook is required but was not found in PATH"
    exit 1
  fi

  for scenario in "${POSITIVE_SCENARIOS[@]}"; do
    run_positive_scenario "${scenario}" || exit 1
  done

  echo "All add_nodes scenario tests passed."
}

main "$@"
