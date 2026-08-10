BASE_IMAGE ?= quay.io/redhat-consulting-services/ee-openshift
OPENSHIFT_VERSION ?= 4.22.6
LATEST_TAG ?= $(shell git tag --sort=-version:refname | head -n1)
CREDENTIALS_FOLDER ?= ./credentials
DESTINATION_AUTH_CONFIG ?= docker_local_pull_secret.json
SOURCE_AUTH_CONFIG ?= openshift_pull_secret.json

DESTINATION_AUTH_CONFIG_FILE=${CREDENTIALS_FOLDER}/${DESTINATION_AUTH_CONFIG}
SOURCE_AUTH_CONFIG_FILE=${CREDENTIALS_FOLDER}/${SOURCE_AUTH_CONFIG}

EE_CREDENTIALS_FILE=${CREDENTIALS_FOLDER}/ee_credentials.yaml

.PHONY: vars
vars:
	@echo "mirror:" > ${EE_CREDENTIALS_FILE}
	@echo "  destination:" >> ${EE_CREDENTIALS_FILE}
	@echo "    auth_config: '$$(jq -c . ${DESTINATION_AUTH_CONFIG_FILE})'" >> ${EE_CREDENTIALS_FILE}
	@echo "  source:" >> ${EE_CREDENTIALS_FILE}
	@echo "    auth_config: '$$(jq -c . ${SOURCE_AUTH_CONFIG_FILE})'" >> ${EE_CREDENTIALS_FILE}

.PHONY: debug
debug:
	@echo "BASE_IMAGE: ${BASE_IMAGE}"
	@echo "OPENSHIFT_VERSION: ${OPENSHIFT_VERSION}"
	@echo "LATEST_TAG: ${LATEST_TAG}"
	@echo "CREDENTIALS_FOLDER: ${CREDENTIALS_FOLDER}"
	@echo "DESTINATION_AUTH_CONFIG: ${DESTINATION_AUTH_CONFIG}"
	@echo "SOURCE_AUTH_CONFIG: ${SOURCE_AUTH_CONFIG}"
	@echo "DESTINATION_AUTH_CONFIG_JSON: $$(jq -c . ${DESTINATION_AUTH_CONFIG_FILE})"
	@echo "SOURCE_AUTH_CONFIG_JSON: $$(jq -c . ${SOURCE_AUTH_CONFIG_FILE})"

.PHONY: test
test: test-basic test-basic-mirror

.PHONY: test-basic
test-basic:
	mkdir -p basic/_generated

	@echo "Executing basic tests..."
	ansible-navigator run basic/playbook.yaml \
		-m stdout \
		--eei ${BASE_IMAGE}:${LATEST_TAG}-ocp-${OPENSHIFT_VERSION}-latest \
		--eev basic/_generated:/opt/oc-mirror:Z \
		--eev ../../mirror_images:/opt/roles/mirror_images:Z \
		--eev ${CREDENTIALS_FOLDER}:/opt/credentials:Z \
		-e @basic/vars.yaml \
		-e oc_mirror_base_path=/opt/oc-mirror \
		-e @${EE_CREDENTIALS_FILE}

	@echo "Reformatting generated files..."
	SOURCE_DIR=basic/_generated/image-sets ../../../scripts/re-format-yaml.sh

	@echo "Reformatting expected files..."
	SOURCE_DIR=basic/expected ../../../scripts/re-format-yaml.sh

	@echo "Comparing generated files with expected files..."
	diff -r basic/_generated/image-sets basic/expected

.PHONY: test-basic-mirror
test-basic-mirror:
	mkdir -p basic-mirror/_generated

	@echo "Executing basic-mirror tests..."
	ansible-navigator run basic-mirror/playbook.yaml \
		-m stdout \
		--eei ${BASE_IMAGE}:${LATEST_TAG}-ocp-${OPENSHIFT_VERSION}-latest \
		--eev basic-mirror/_generated:/opt/oc-mirror:Z \
		--eev ../../mirror_images:/opt/roles/mirror_images:Z \
		--eev ${CREDENTIALS_FOLDER}:/opt/credentials:Z \
		-e @basic-mirror/vars.yaml \
		-e oc_mirror_base_path=/opt/oc-mirror \
		-e @${EE_CREDENTIALS_FILE}

	@echo "Reformatting generated files..."
	SOURCE_DIR=basic-mirror/_generated/image-sets ../../../scripts/re-format-yaml.sh

	@echo "Reformatting expected files..."
	SOURCE_DIR=basic-mirror/expected ../../../scripts/re-format-yaml.sh

	@echo "Comparing generated files with expected files..."
	diff -r basic-mirror/_generated/image-sets basic-mirror/expected
