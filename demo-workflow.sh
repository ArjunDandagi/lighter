#!/bin/bash
# Complete workflow demonstration for testing Lighter with Kind
# This script demonstrates all the steps but allows skipping the time-consuming build

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

section "Complete Lighter Testing Workflow with Kind"

info "This script demonstrates the complete workflow for testing Lighter"
info "on a Kind (Kubernetes in Docker) cluster with Spark support."
echo ""

# Step 1: Setup Kind cluster
section "Step 1: Setting up Kind Cluster"
info "Creating a Kind cluster with Kubernetes..."

if kind get clusters 2>/dev/null | grep -q "^lighter-test$"; then
    info "Kind cluster 'lighter-test' already exists"
    read -p "Do you want to recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./cleanup-kind.sh
        ./setup-kind.sh
    fi
else
    ./setup-kind.sh
fi

success "Kind cluster is ready"
kubectl cluster-info --context kind-lighter-test

# Step 2: Build Lighter image
section "Step 2: Building Lighter Image"
info "Building the Lighter Docker image with Spark..."
echo ""
echo "NOTE: Building takes 10-15 minutes as it:"
echo "  - Builds the backend with Gradle"
echo "  - Downloads Apache Spark 3.5.6"
echo "  - Builds the frontend with Yarn"
echo ""

if docker image inspect lighter:test &> /dev/null; then
    info "Lighter image 'lighter:test' already exists"
    read -p "Do you want to rebuild it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        success "Using existing image"
    else
        info "Building image... (this will take 10-15 minutes)"
        docker build -t lighter:test . || {
            echo "Build failed. You can also try:"
            echo "  docker compose -f docker-compose.test.yml --profile build up"
            exit 1
        }
        success "Image built successfully"
    fi
else
    read -p "Build the image now? This takes 10-15 minutes. (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Building image... (this will take 10-15 minutes)"
        docker build -t lighter:test . || {
            echo "Build failed. You can also try:"
            echo "  docker compose -f docker-compose.test.yml --profile build up"
            exit 1
        }
        success "Image built successfully"
    else
        info "Skipping build. You can build later with:"
        info "  docker build -t lighter:test ."
        info "  OR"
        info "  docker compose -f docker-compose.test.yml --profile build up"
        exit 0
    fi
fi

# Step 3: Load image to Kind
section "Step 3: Loading Image into Kind"
info "Loading the Lighter image into the Kind cluster..."

./load-image-to-kind.sh
success "Image loaded into Kind"

# Step 4: Deploy Lighter
section "Step 4: Deploying Lighter to Kind"
info "Deploying Lighter with Spark to Kubernetes..."

./deploy-lighter-to-kind.sh
success "Lighter deployed successfully"

# Step 5: Verify deployment
section "Step 5: Verifying Deployment"
info "Checking deployed resources..."

kubectl get all -n spark
echo ""

# Check if Lighter is accessible
info "Checking if Lighter API is accessible..."
sleep 5  # Give it a moment

if curl -s http://localhost:8080/health/readiness > /dev/null; then
    success "Lighter API is accessible!"
else
    info "Lighter may still be starting up. Check with:"
    info "  kubectl logs -f deployment/lighter -n spark"
fi

# Step 6: Usage examples
section "Step 6: Usage Examples"

echo "Lighter is now running! Here's how to use it:"
echo ""
echo "📍 Access Points:"
echo "  • Lighter UI:   http://localhost:8080/lighter/"
echo "  • Swagger API:  http://localhost:8080/swagger-ui/"
echo "  • Health Check: http://localhost:8080/health/readiness"
echo ""
echo "🚀 Submit a Spark job:"
echo ""
echo "curl -X POST http://localhost:8080/lighter/api/batches \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo "    \"name\": \"Spark PI\","
echo "    \"file\": \"/home/app/spark/examples/jars/spark-examples_2.12-3.5.6.jar\","
echo "    \"mainClass\": \"org.apache.spark.examples.SparkPi\","
echo "    \"args\": [\"100\"]"
echo "  }'"
echo ""
echo "📊 Check job status:"
echo "  curl http://localhost:8080/lighter/api/batches"
echo ""
echo "📝 View logs:"
echo "  kubectl logs -f deployment/lighter -n spark"
echo ""
echo "👀 Watch Spark pods:"
echo "  kubectl get pods -n spark -w"
echo ""
echo "🧹 Clean up when done:"
echo "  ./cleanup-kind.sh"
echo ""

success "Setup complete! Lighter is ready for testing."
