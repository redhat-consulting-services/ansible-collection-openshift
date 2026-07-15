COLLECTION_SOURCE_PATH ?= .
COLLECTION_BUILD_DIR = ./collections

CONTAINER_RUNTIME ?= podman

OPENSHIFT_VERSION ?= 4.22.4
EE_VERSION ?= 0.0.0-rc.1
EE_TAG ?= example.com/redhat/ee-openshift:v${EE_VERSION}

build-collection:
	ansible-galaxy collection build ${COLLECTION_SOURCE_PATH} \
		--output-path ${COLLECTION_BUILD_DIR} \
		--force

build-ee:
	ansible-builder build \
		--tag ${EE_TAG} \
		--container-runtime ${CONTAINER_RUNTIME} \
		--build-arg OPENSHIFT_VERSION=${OPENSHIFT_VERSION} \
		--context .
