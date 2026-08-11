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
	mkdir -p ${CREDENTIALS_FOLDER}
	@echo "mirror:" > ${EE_CREDENTIALS_FILE}
	@echo "  destination:" >> ${EE_CREDENTIALS_FILE}
	@echo "    auth_config: |" >> ${EE_CREDENTIALS_FILE}
	@jq . ${DESTINATION_AUTH_CONFIG_FILE} | sed 's/^/      /' >> ${EE_CREDENTIALS_FILE}
	@echo "  source:" >> ${EE_CREDENTIALS_FILE}
	@echo "    auth_config: |" >> ${EE_CREDENTIALS_FILE}
	@jq . ${SOURCE_AUTH_CONFIG_FILE} | sed 's/^/      /' >> ${EE_CREDENTIALS_FILE}

TEST_DIR ?= basic

.PHONY: merge
merge:
	mkdir -p ${TEST_DIR}/_generated
	@echo "Merging ${EE_CREDENTIALS_FILE} with ${TEST_DIR}/vars.yaml..."
	yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' ${EE_CREDENTIALS_FILE} ${TEST_DIR}/vars.yaml > ${TEST_DIR}/_generated/merged.yaml

.PHONY: test
test: vars
	export TEST_DIR=basic
	$(MAKE) run-test
	export TEST_DIR=basic-mirror
	$(MAKE) run-test

.PHONY: test-basic
run-test: vars merge
	mkdir -p ${TEST_DIR}/_generated

	@echo "Executing basic tests..."
	ansible-navigator run basic/playbook.yaml \
		-m stdout \
		--eei ${BASE_IMAGE}:${LATEST_TAG}-ocp-${OPENSHIFT_VERSION}-latest \
		--eev ${TEST_DIR}/_generated:/opt/oc-mirror:Z \
		--eev ../../mirror_images:/opt/roles/mirror_images:Z \
		--eev ${CREDENTIALS_FOLDER}:/opt/credentials:Z \
		-e @${TEST_DIR}/_generated/merged.yaml \
		-e oc_mirror_base_path=/opt/oc-mirror

	@echo "Reformatting generated files..."
	SOURCE_DIR=${TEST_DIR}/_generated/image-sets ../../../scripts/re-format-yaml.sh

	@echo "Reformatting expected files..."
	SOURCE_DIR=${TEST_DIR}/expected ../../../scripts/re-format-yaml.sh

	@echo "Comparing generated files with expected files..."
	diff -r ${TEST_DIR}/_generated/image-sets ${TEST_DIR}/expected
