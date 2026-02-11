#!/bin/bash
set -e

echo "==> Loading Lighter image into Kind cluster..."

CLUSTER_NAME="${KIND_CLUSTER_NAME:-lighter-test}"
IMAGE_NAME="${LIGHTER_IMAGE:-lighter:test}"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed."
    exit 1
fi

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "Error: Kind cluster '${CLUSTER_NAME}' does not exist."
    echo "Run ./setup-kind.sh first to create the cluster."
    exit 1
fi

# Check if image exists
if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
    echo "Error: Docker image '${IMAGE_NAME}' not found."
    echo "Build the image first with: docker-compose -f docker-compose.test.yml --profile build up"
    exit 1
fi

echo "==> Loading image '${IMAGE_NAME}' into Kind cluster '${CLUSTER_NAME}'..."
kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"

echo "==> Image loaded successfully!"
echo ""
echo "Next step: Deploy Lighter with ./deploy-lighter-to-kind.sh"
