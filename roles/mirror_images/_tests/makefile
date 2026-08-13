COLOR_RED := \033[31m
COLOR_GREEN := \033[32m
COLOR_BLUE := \033[34m
COLOR_RESET := \033[0m

BASE_IMAGE ?= quay.io/redhat-consulting-services/ee-openshift
OPENSHIFT_VERSION ?= 4.22.6
LATEST_TAG ?= $(shell git tag --sort=-version:refname | head -n1)
CREDENTIALS_FOLDER ?= ./credentials
DESTINATION_AUTH_CONFIG ?= docker_local_pull_secret.json
SOURCE_AUTH_CONFIG ?= openshift_pull_secret.json

### DESTINATION_AUTH_CONFIG_FILE=${CREDENTIALS_FOLDER}/${DESTINATION_AUTH_CONFIG}
SOURCE_REGISTRY_AUTH_CONFIG_FILE=${CREDENTIALS_FOLDER}/${SOURCE_AUTH_CONFIG}

###########################################
### Execution environment specific vars ###
###########################################
EE_CREDENTIALS_FILE=${CREDENTIALS_FOLDER}/ee_credentials.yaml

###########################################
### Execution environment specific vars ###
###########################################
CONTAINER_RUNTIME ?= $(shell basename $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null))


####################################
### local registry configuration ###
####################################
REGISTRY_BASE_FOLDER ?= ./registry
REGISTRY_VOLUME_FOLDER ?= ${REGISTRY_BASE_FOLDER}/volume
REGISTRY_AUTH_FOLDER ?= ${REGISTRY_BASE_FOLDER}/auth
REGISTRY_AUTH_JSON_FILE ?= ${REGISTRY_AUTH_FOLDER}/auth.json
REGISTRY_CONTAINER_NAME ?= registry
REGISTRY_USERNAME ?= testuser
REGISTRY_PASSWORD ?= testpassword
REGISTRY_PORT ?= 5001
REGISTRY_HOSTNAME ?= registry.local
REGISTRY_FQDN ?= ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}
REGISTRY_MAX_RETRY ?= 30

.PHONY: all
all: help

##@ Helpers for tests

.PHONY: vars
vars: registry-credential ## Create the ee_credentials.yaml file from the source and destination auth config files.
	mkdir -p ${CREDENTIALS_FOLDER}
	@echo "mirror:" > ${EE_CREDENTIALS_FILE}
	@echo "  destination:" >> ${EE_CREDENTIALS_FILE}
	@echo "    auth_config: |" >> ${EE_CREDENTIALS_FILE}
	@jq . ${REGISTRY_AUTH_JSON_FILE} | sed 's/^/      /' >> ${EE_CREDENTIALS_FILE}
	@echo "  source:" >> ${EE_CREDENTIALS_FILE}
	@echo "    auth_config: |" >> ${EE_CREDENTIALS_FILE}
	@jq . ${SOURCE_REGISTRY_AUTH_CONFIG_FILE} | sed 's/^/      /' >> ${EE_CREDENTIALS_FILE}

TEST_DIR ?= basic

.PHONY: merge
merge: ## Merge the REGISTRY_AUTH_JSON_FILE and SOURCE_REGISTRY_AUTH_CONFIG_FILE into a single vars.yaml file for the specified TEST_DIR.
	mkdir -p ${TEST_DIR}/_generated
	@echo "Merging ${EE_CREDENTIALS_FILE} with ${TEST_DIR}/vars.yaml..."
	yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' ${EE_CREDENTIALS_FILE} ${TEST_DIR}/vars.yaml > ${TEST_DIR}/_generated/merged.yaml

##@ Test execution

.PHONY: test
test: vars ## Execute all tests.
	TEST_DIR=basic $(MAKE) run-test
	TEST_DIR=basic-mirror $(MAKE) run-test
	TEST_DIR=basic-openshift $(MAKE) run-test

.PHONY: test-basic
run-test: vars merge ## Execute a single test in the specified TEST_DIR. Usage: TEST_DIR=<test_directory> make run-test
	mkdir -p ${TEST_DIR}/_generated

	@echo "${COLOR_BLUE}===============================${COLOR_RESET}"
	@echo "${COLOR_BLUE}Executing ${TEST_DIR} tests...${COLOR_RESET}"
	@echo "${COLOR_BLUE}===============================${COLOR_RESET}"
	ansible-navigator run ${TEST_DIR}/playbook.yaml \
		-m stdout \
		--container-options="--add-host=registry.local:host-gateway" \
		--eei ${BASE_IMAGE}:${LATEST_TAG}-ocp-${OPENSHIFT_VERSION}-latest \
		--eev ${TEST_DIR}/_generated:/opt/oc-mirror:Z \
		--eev ../../mirror_images:/opt/roles/mirror_images:Z \
		--eev ${CREDENTIALS_FOLDER}:/opt/credentials:Z \
		-e @${TEST_DIR}/_generated/merged.yaml \
		-e oc_mirror_base_path=/opt/oc-mirror \
		-vvv

	@echo "Reformatting generated files..."
	SOURCE_DIR=${TEST_DIR}/_generated/image-sets ../../../scripts/re-format-yaml.sh

	@echo "Reformatting expected files..."
	SOURCE_DIR=${TEST_DIR}/expected ../../../scripts/re-format-yaml.sh

	@echo "Comparing generated files with expected files..."
	diff -r ${TEST_DIR}/_generated/image-sets ${TEST_DIR}/expected || \
		(echo "${COLOR_RED}Executing ${TEST_DIR} failed!${COLOR_RESET}" && exit 1)

##@ Registry

.PHONY: registry
registry: ## Start a local registry for testing.
	mkdir -p ${REGISTRY_VOLUME_FOLDER} ${REGISTRY_AUTH_FOLDER}
	htpasswd -Bbn "${REGISTRY_USERNAME}" "${REGISTRY_PASSWORD}" > ${REGISTRY_AUTH_FOLDER}/htpasswd
	$(CONTAINER_RUNTIME) run -d -p ${REGISTRY_PORT}:5000 \
		--restart always \
		--name ${REGISTRY_CONTAINER_NAME} \
		--hostname ${REGISTRY_HOSTNAME} \
		-e REGISTRY_AUTH=htpasswd \
		-e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
		-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
		-v ${REGISTRY_AUTH_FOLDER}:/auth \
		-v ${REGISTRY_VOLUME_FOLDER}:/var/lib/registry \
		registry:3
	$(CONTAINER_RUNTIME) ps
	@echo "Waiting for the registry to be ready..."
	sleep 5
	@attempt=0; \
	while ! curl -s http://${REGISTRY_FQDN}/v2/ > /dev/null; do \
		attempt=$$(($${attempt}+1)); \
		if [ "$${attempt}" -ge "${REGISTRY_MAX_RETRY}" ]; then \
			echo "Registry did not become ready after ${REGISTRY_MAX_RETRY} attempts" >&2; \
			exit 1; \
		fi; \
		echo "Waiting for the registry to be ready... ($${attempt}/${REGISTRY_MAX_RETRY})"; \
		sleep 2; \
	done
	@echo "Registry is ready."

.PHONY: registry-stop
registry-stop: ## Stop and remove the local registry container.
	$(CONTAINER_RUNTIME) stop ${REGISTRY_CONTAINER_NAME} || true
	$(CONTAINER_RUNTIME) rm ${REGISTRY_CONTAINER_NAME} || true

.PHONY: registry-clean
registry-clean: ## Clean up the local registry data and authentication files.
	rm -rf ${REGISTRY_BASE_FOLDER}
.PHONY: registry-credential
registry-credential: ## Create registry credential file for the local registry. Depends on the container engine being used (Podman or Docker).
	@echo "Using container engine: ${CONTAINER_RUNTIME}"
	@if [ "${CONTAINER_RUNTIME}" = "podman" ]; then \
		$(MAKE) registry-credential-podman; \
	else \
		$(MAKE) registry-credential-docker; \
	fi

.PHONY: registry-credential-podman
registry-credential-podman: ## Create Podman registry credential file for the local registry.
	mkdir -p ${REGISTRY_AUTH_FOLDER}
	echo "${REGISTRY_PASSWORD}" | podman login --authfile ${REGISTRY_AUTH_JSON_FILE} -v --tls-verify=false ${REGISTRY_FQDN} -u "${REGISTRY_USERNAME}" --password-stdin

.PHONY: registry-credential-docker
registry-credential-docker: ## Create Docker registry credential file for the local registry.
	mkdir -p ${REGISTRY_AUTH_FOLDER}
	echo "Using Docker"
	echo "${REGISTRY_PASSWORD}" | docker login --config "${REGISTRY_AUTH_FOLDER}" -v --tls-verify=false ${REGISTRY_FQDN} -u "${REGISTRY_USERNAME}" --password-stdin
	cp "${REGISTRY_AUTH_FOLDER}/config.json" "${REGISTRY_AUTH_JSON_FILE}"

##@ Other

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
