#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${TESTS_DIR}/common"
SCENARIOS_DIR="${TESTS_DIR}/scenarios"

POSITIVE_SCENARIOS=(
  single-stack-ipv4
  dual-stack-vips
  single-ipv6-vip
  dual-stack-host-networking
  user-managed
  interface-addresses
  interface-dual-stack
  no-workers
  bond-ipv4-dhcp
)

NEGATIVE_SCENARIOS=(
  invalid-user-managed-with-vips
  invalid-missing-vips
  invalid-too-many-vips
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

run_negative_scenario() {
  local scenario="$1"
  local scenario_dir="${SCENARIOS_DIR}/${scenario}"
  local output_dir="${scenario_dir}/output"

  rm -rf "${output_dir}"
  mkdir -p "${output_dir}"

  echo "==> Running negative scenario: ${scenario}"
  cd "${COMMON_DIR}"
  if ! ansible-playbook run-negative-scenario.yaml \
    -e "@${scenario_dir}/vars.yaml" \
    -e "scenario_name=${scenario}" \
    -e "scenario_output_dir=${output_dir}"; then
    echo "ERROR: negative scenario ${scenario} failed"
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

  for scenario in "${NEGATIVE_SCENARIOS[@]}"; do
    run_negative_scenario "${scenario}" || exit 1
  done

  echo "All bootstrap_cluster scenario tests passed."
}

main "$@"
