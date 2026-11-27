COLLECTION_SOURCE_PATH ?= .
COLLECTION_BUILD_DIR = ./collections

CONTAINER_RUNTIME ?= podman

OPENSHIFT_VERSION ?= 5.0.3
EE_VERSION ?= 0.0.0-rc.0
EE_TAG ?= example.com/redhat/ee-openshift:v${EE_VERSION}

.PHONY: copy-dev-files
copy-dev-files:
	cp ee-requirements.yml ee-requirements.bkp.yml
	cp ee-requirements.dev.yml ee-requirements.yml

	cp execution-environment.yml execution-environment.bkp.yml
	cp execution-environment.dev.yml execution-environment.yml

.PHONY: copy-prod-files
copy-prod-files:
	mv ee-requirements.bkp.yml ee-requirements.yml
	mv execution-environment.bkp.yml execution-environment.yml

.PHONY: build-collection
build-collection:
	yq -i '.version = "${EE_VERSION}"' galaxy.yml
	ansible-galaxy collection build ${COLLECTION_SOURCE_PATH} \
		--output-path ${COLLECTION_BUILD_DIR} \
		--force

.PHONY: build-ee
build-ee:
	ansible-builder build \
		--tag ${EE_TAG} \
		--container-runtime ${CONTAINER_RUNTIME} \
		--build-arg OPENSHIFT_VERSION=${OPENSHIFT_VERSION} \
	        --prune-images \
		--squash all \
		--context .

.PHONY: all
all: copy-dev-files build-collection build-ee copy-prod-files
