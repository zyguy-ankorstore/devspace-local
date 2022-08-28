CLUSTER_NAME := "devspace"
KIND_VERSION := "v0.14.0"
ISTIO_VERSION := "1.15.0-beta.1"
REG_NAME := "kind-registry"
REG_PORT := 5001


.PHONE: install-registry
install-registry:
	@if [ "$(shell docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)" != 'true' ]; then docker run -d --restart=always -p "127.0.0.1:${REG_PORT}:5000" --name "${REG_NAME}" registry:2; fi

.PHONY: connect-registry
connect-registry:
	@if [ "$(shell docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REG_NAME}")" = 'null' ]; then docker network connect "kind" "${REG_NAME}"; fi
#	envsubst < hack/registry-configmap.yaml | kubectl apply -f-

.PHONY: bootstrap-registry
bootstrap-registry: install-registry 

.PHONY: install-kind
install-kind:
	go install sigs.k8s.io/kind@$(KIND_VERSION)

.PHONY: ensure-context
ensure-context:
	kubectl config use-context kind-$(CLUSTER_NAME)

.PHONY: install-istioctl
install-istioctl:
	curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$(ISTIO_VERSION) sh -
	mkdir -p .bin
	mv istio-$(ISTIO_VERSION)/bin/istioctl .bin/istioctl
	rm -R istio-$(ISTIO_VERSION)

.PHONY: bootstrap
bootstrap: bootstrap-registry bootstrap-cluster bootstrap-istio connect-registry

.PHONY: bootstrap-cluster
bootstrap-cluster: install-kind
# DOCKER_DEFAULT_PLATFORM=linux/amd64 kind create cluster --config ./hack/cluster.yaml --wait 120s --name=$(CLUSTER_NAME)
	kind create cluster --config hack/cluster.yaml --wait 120s --name=$(CLUSTER_NAME)

.PHONY: bootstrap-istio
bootstrap-istio: install-istioctl ensure-context
	# Install istio
	.bin/istioctl install -y --verify -f hack/istio-operator.yaml

.PHONE: install-devspace
install-devspace:
	brew install devspace

# Teardown everything
.PHONY: teardown
teardown:
	kind delete cluster --name=$(CLUSTER_NAME)
	docker rm -f ${REG_NAME}
