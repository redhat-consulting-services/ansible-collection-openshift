#!/usr/bin/env bash
# Run collection role tests (offline, mocked kubernetes / CLI tools).
# Each option case runs in a fresh ansible-playbook process to avoid fact bleed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="${ROOT_DIR}/tests"
ARTIFACT_DIR="${TEST_DIR}/.artifacts"
MOCK_BIN="${TEST_DIR}/mocks/bin"
MOCK_STATE="${ARTIFACT_DIR}/k8s-mock-state.json"

export PATH="${MOCK_BIN}:${PATH}"
export ANSIBLE_CONFIG="${TEST_DIR}/ansible.cfg"
export ANSIBLE_COLLECTIONS_PATH="${TEST_DIR}/collections:${HOME}/.ansible/collections:/usr/share/ansible/collections"
export ANSIBLE_ROLES_PATH="${ROOT_DIR}/roles"
export ANSIBLE_K8S_MOCK_STATE="${MOCK_STATE}"
export ANSIBLE_LOCAL_TEMP="${ARTIFACT_DIR}/ansible-tmp"
export ANSIBLE_REMOTE_TEMP="${ARTIFACT_DIR}/ansible-tmp"

mkdir -p "${ARTIFACT_DIR}/ansible-tmp"
chmod +x "${MOCK_BIN}"/*

cd "${TEST_DIR}"

if [[ "${SKIP_GALAXY_INSTALL:-0}" != "1" ]]; then
  echo "==> Installing test dependencies (ansible.utils, community.general)"
  ansible-galaxy collection install -r requirements.yml -p ./collections --force
  if ! grep -q 'Mock kubernetes.core' ./collections/ansible_collections/kubernetes/core/README.md 2>/dev/null; then
    echo "ERROR: mock kubernetes.core collection is missing or was overwritten"
    exit 1
  fi
fi

TARGETS=("$@")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(
    bootstrap_cluster
    add_nodes
    mirror_images
    configure_olm
    bootstrap_gitops
    configure_nodes
    cluster_installation_check
  )
fi

FAILED=0
PASSED=0
CASE_FAILED=0
CASE_PASSED=0

for role in "${TARGETS[@]}"; do
  playbook="integration/${role}/test.yml"
  cases_dir="integration/${role}/cases"

  if [[ ! -f "${playbook}" ]]; then
    echo "ERROR: missing ${playbook}"
    FAILED=$((FAILED + 1))
    continue
  fi

  if [[ ! -d "${cases_dir}" ]]; then
    echo "ERROR: missing ${cases_dir}"
    FAILED=$((FAILED + 1))
    continue
  fi

  echo ""
  echo "============================================================"
  echo "==> Testing role: ${role}"
  echo "============================================================"

  role_failed=0
  mkdir -p "${ARTIFACT_DIR}/${role}"

  while IFS= read -r -d '' case_file; do
    case_name="$(basename "${case_file}" .yml)"
    echo "--> case: ${case_name}"
    rm -f "${MOCK_STATE}"

    # Resolve to absolute path; include_vars is relative to the playbook dir
    case_file_abs="$(cd "$(dirname "${case_file}")" && pwd)/$(basename "${case_file}")"

    if ansible-playbook "${playbook}" \
        -e "test_artifact_dir=${ARTIFACT_DIR}/${role}" \
        -e "test_mock_state=${MOCK_STATE}" \
        -e "case_file_path=${case_file_abs}"; then
      echo "    PASS: ${role}/${case_name}"
      CASE_PASSED=$((CASE_PASSED + 1))
    else
      echo "    FAIL: ${role}/${case_name}"
      CASE_FAILED=$((CASE_FAILED + 1))
      role_failed=1
    fi
  done < <(find "${cases_dir}" -maxdepth 1 -type f -name '*.yml' -print0 | sort -z)

  if [[ "${role_failed}" -eq 0 ]]; then
    echo "PASS: ${role}"
    PASSED=$((PASSED + 1))
  else
    echo "FAIL: ${role}"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "============================================================"
echo "Roles: ${PASSED} passed, ${FAILED} failed"
echo "Cases: ${CASE_PASSED} passed, ${CASE_FAILED} failed"
echo "============================================================"

if [[ "${FAILED}" -gt 0 || "${CASE_FAILED}" -gt 0 ]]; then
  exit 1
fi
