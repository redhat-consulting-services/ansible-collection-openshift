BASE_IMAGE ?= quay.io/redhat-consulting-services/ee-openshift
OPENSHIFT_VERSION ?= 4.22.6
LATEST_TAG ?= $(shell git tag --sort=-version:refname | head -n1)
VOLUME ?= ./
DESTINATION_AUTH_CONFIG ?= docker_local_pull_secret.json
SOURCE_AUTH_CONFIG ?= openshift_pull_secret.json

.PHONY: test
test: test-basic

.PHONY: test-basic
test-basic:
	mkdir -p basic/_generated

	@echo "Executing basic tests..."
	ansible-navigator run basic/playbook.yaml \
		-m stdout \
		--eei ${BASE_IMAGE}:${LATEST_TAG}-ocp-${OPENSHIFT_VERSION}-latest \
		--eev basic/_generated:/opt/oc-mirror:Z \
		--eev ../../mirror_images:/opt/roles/mirror_images:Z \
		-e @basic/vars.yaml \
		-e oc_mirror_base_path=/opt/oc-mirror \
		-e "mirror.destination.auth_config=$$(tr -d '\n' < ${DESTINATION_AUTH_CONFIG})" \
		-e "mirror.source.auth_config=$$(tr -d '\n' < ${SOURCE_AUTH_CONFIG})"

	@echo "Reformatting generated files..."
	SOURCE_DIR=basic/_generated/image-sets ../../../scripts/re-format-yaml.sh

	@echo "Reformatting expected files..."
	SOURCE_DIR=basic/expected ../../../scripts/re-format-yaml.sh

	@echo "Comparing generated files with expected files..."
	diff -r basic/_generated/image-sets basic/expected
