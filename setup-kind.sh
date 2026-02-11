#!/bin/bash
set -e

echo "==> Setting up Kind cluster for Lighter testing..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed. Please install kind first."
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed. Please install docker first."
    exit 1
fi

CLUSTER_NAME="${KIND_CLUSTER_NAME:-lighter-test}"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "Kind cluster '${CLUSTER_NAME}' already exists."
    read -p "Do you want to delete and recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "==> Deleting existing cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo "Using existing cluster."
        exit 0
    fi
fi

# Create kind cluster with custom configuration
echo "==> Creating Kind cluster '${CLUSTER_NAME}'..."
cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
EOF

echo "==> Kind cluster created successfully!"

# Set kubectl context
echo "==> Setting kubectl context..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo ""
echo "==> Setup complete!"
echo "Cluster name: ${CLUSTER_NAME}"
echo "To use this cluster, run: kubectl config use-context kind-${CLUSTER_NAME}"
echo ""
echo "Next steps:"
echo "  1. Build Lighter image: docker-compose -f docker-compose.test.yml --profile build up"
echo "  2. Load image to Kind: ./load-image-to-kind.sh"
echo "  3. Deploy Lighter: ./deploy-lighter-to-kind.sh"
