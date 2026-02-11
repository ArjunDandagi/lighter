#!/bin/bash
set -e

echo "=========================================="
echo "Testing Lighter with Kind - Quick Validation"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# Test 1: Check required tools
echo "Test 1: Checking required tools..."
if command -v kind &> /dev/null; then
    success "kind is installed ($(kind version))"
else
    error "kind is not installed"
    exit 1
fi

if command -v kubectl &> /dev/null; then
    success "kubectl is installed ($(kubectl version --client -o yaml | grep gitVersion | head -1))"
else
    error "kubectl is not installed"
    exit 1
fi

if command -v docker &> /dev/null; then
    success "docker is installed ($(docker --version))"
else
    error "docker is not installed"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    success "docker-compose is installed ($(docker-compose --version))"
else
    warning "docker-compose is not installed (optional)"
fi

echo ""

# Test 2: Check if Kind cluster exists
echo "Test 2: Checking Kind cluster..."
if kind get clusters 2>/dev/null | grep -q "lighter-test"; then
    success "Kind cluster 'lighter-test' exists"
    
    # Verify it's running
    if docker ps | grep -q "lighter-test-control-plane"; then
        success "Kind cluster is running"
    else
        error "Kind cluster exists but is not running"
        exit 1
    fi
else
    error "Kind cluster 'lighter-test' does not exist"
    echo "  Run ./setup-kind.sh to create it"
    exit 1
fi

echo ""

# Test 3: Check kubectl connectivity
echo "Test 3: Checking kubectl connectivity..."
if kubectl cluster-info --context kind-lighter-test &> /dev/null; then
    success "kubectl can connect to Kind cluster"
    
    # Get node info
    NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$NODE_STATUS" = "True" ]; then
        success "Cluster node is Ready"
    else
        warning "Cluster node is not Ready yet"
    fi
else
    error "Cannot connect to Kind cluster with kubectl"
    exit 1
fi

echo ""

# Test 4: Check Docker and Dockerfile
echo "Test 4: Checking Dockerfile..."
if [ -f "Dockerfile" ]; then
    success "Dockerfile exists"
    
    # Check for key components in Dockerfile
    if grep -q "SPARK_VERSION" Dockerfile; then
        success "Dockerfile contains Spark configuration"
    fi
    
    if grep -q "server/" Dockerfile; then
        success "Dockerfile includes server build"
    fi
    
    if grep -q "frontend/" Dockerfile; then
        success "Dockerfile includes frontend build"
    fi
else
    error "Dockerfile not found"
    exit 1
fi

echo ""

# Test 5: Check docker-compose.test.yml
echo "Test 5: Checking docker-compose.test.yml..."
if [ -f "docker-compose.test.yml" ]; then
    success "docker-compose.test.yml exists"
    
    # Validate it's proper YAML
    if docker-compose -f docker-compose.test.yml config &> /dev/null; then
        success "docker-compose.test.yml is valid YAML"
    else
        warning "docker-compose.test.yml may have syntax issues"
    fi
else
    error "docker-compose.test.yml not found"
    exit 1
fi

echo ""

# Test 6: Check helper scripts
echo "Test 6: Checking helper scripts..."
for script in setup-kind.sh load-image-to-kind.sh deploy-lighter-to-kind.sh cleanup-kind.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            success "$script exists and is executable"
        else
            warning "$script exists but is not executable (run: chmod +x $script)"
        fi
    else
        error "$script not found"
    fi
done

echo ""

# Test 7: Check Kubernetes manifests
echo "Test 7: Checking Kubernetes manifests..."
if [ -d "quickstart" ]; then
    success "quickstart directory exists"
    
    if [ -f "quickstart/lighter.yml" ]; then
        success "quickstart/lighter.yml exists"
        
        # Validate K8s YAML
        if kubectl apply --dry-run=client -f quickstart/lighter.yml &> /dev/null; then
            success "quickstart/lighter.yml is valid Kubernetes manifest"
        else
            warning "quickstart/lighter.yml may have validation issues"
        fi
    fi
fi

if [ -d "k8s" ]; then
    success "k8s directory exists (pod templates)"
fi

echo ""

# Test 8: Check documentation
echo "Test 8: Checking documentation..."
if [ -f "TESTING.md" ]; then
    success "TESTING.md exists"
else
    warning "TESTING.md not found"
fi

if [ -f "README.md" ]; then
    success "README.md exists"
fi

echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""
success "All critical components are in place!"
echo ""
echo "Next steps to test the complete workflow:"
echo ""
echo "1. Build the Lighter image (takes 10-15 minutes):"
echo "   docker build -t lighter:test ."
echo "   OR"
echo "   docker-compose -f docker-compose.test.yml --profile build up"
echo ""
echo "2. Load the image into Kind:"
echo "   ./load-image-to-kind.sh"
echo ""
echo "3. Deploy Lighter to Kind:"
echo "   ./deploy-lighter-to-kind.sh"
echo ""
echo "4. Access Lighter:"
echo "   http://localhost:8080/lighter/"
echo ""
echo "5. Test with a Spark job:"
echo "   curl -X POST http://localhost:8080/lighter/api/batches \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"name\": \"Spark PI\", "
echo "          \"file\": \"/home/app/spark/examples/jars/spark-examples_2.12-3.5.6.jar\", "
echo "          \"mainClass\": \"org.apache.spark.examples.SparkPi\", "
echo "          \"args\": [\"100\"]}'"
echo ""
echo "To clean up everything:"
echo "   ./cleanup-kind.sh"
echo ""
