BASE_IMAGE ?= quay.io/redhat-consulting-services/ee-openshift
OPENSHIFT_VERSION ?= 4.22.6
LATEST_TAG ?= $(shell git tag --sort=-version:refname | head -n1)
VOLUME_AUTH ?= ./

.PHONY: test
test: test-basic

.PHONY: test-basic
test-basic:
	@echo "Running basic tests..."
	ansible-navigator run basic/playbook.yaml \
		-m stdout \
		--eei ${BASE_IMAGE}:${LATEST_TAG}-ocp-${OPENSHIFT_VERSION}-latest \
		--eev ${VOLUME_AUTH}:/opt/oc-mirror:Z \
		--eev ../../mirror_images:/opt/roles/mirror_images:Z \
		-e @basic/vars.yaml \
		-e oc_mirror_base_path=${VOLUME_AUTH}/_generated
