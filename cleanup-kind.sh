#!/bin/bash
set -e

echo "==> Cleaning up Kind cluster and resources..."

CLUSTER_NAME="${KIND_CLUSTER_NAME:-lighter-test}"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed."
    exit 1
fi

# Check if cluster exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "==> Deleting Kind cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "${CLUSTER_NAME}"
    echo "==> Cluster deleted successfully!"
else
    echo "Kind cluster '${CLUSTER_NAME}' does not exist."
fi

# Optionally clean up Docker images
read -p "Do you want to remove the Lighter test image as well? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    IMAGE_NAME="${LIGHTER_IMAGE:-lighter:test}"
    if docker image inspect "${IMAGE_NAME}" &> /dev/null; then
        echo "==> Removing Docker image '${IMAGE_NAME}'..."
        docker rmi "${IMAGE_NAME}"
        echo "==> Image removed successfully!"
    else
        echo "Docker image '${IMAGE_NAME}' not found."
    fi
fi

echo ""
echo "==> Cleanup complete!"
