# Testing Lighter with Kind (Kubernetes in Docker)

This directory contains scripts and configuration for testing Lighter on a local Kubernetes cluster using [Kind](https://kind.sigs.k8s.io/).

## Prerequisites

Before getting started, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/) (version 20.10+)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (Kubernetes in Docker)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (Kubernetes command-line tool)
- [Docker Compose](https://docs.docker.com/compose/install/) (for building the image)

## Quick Start

Follow these steps to set up and test Lighter with Kind:

### 1. Create the Kind Cluster

```bash
./setup-kind.sh
```

This script will:
- Create a Kind cluster named `lighter-test` (customizable via `KIND_CLUSTER_NAME` env var)
- Configure port mappings for accessing services
- Set up kubectl context

### 2. Build the Lighter Image

```bash
docker-compose -f docker-compose.test.yml --profile build up
```

Or build directly with Docker:

```bash
docker build -t lighter:test .
```

This builds the Lighter Docker image with:
- Apache Spark 3.5.6
- Hadoop 3
- Frontend and backend components

### 3. Load the Image into Kind

```bash
./load-image-to-kind.sh
```

This makes the Lighter image available to the Kind cluster.

### 4. Deploy Lighter to Kind

```bash
./deploy-lighter-to-kind.sh
```

This script will:
- Create the `spark` namespace
- Set up RBAC (ServiceAccount, Role, RoleBinding)
- Deploy Lighter as a Deployment with a Service
- Wait for the pod to be ready

### 5. Access Lighter

Once deployed, you can access Lighter at:

- **Lighter UI**: http://localhost:8080/lighter/
- **Swagger API**: http://localhost:8080/swagger-ui/
- **Health Check**: http://localhost:8080/health/readiness

## Usage Examples

### Check Deployment Status

```bash
kubectl get all -n spark
```

### View Lighter Logs

```bash
kubectl logs -f deployment/lighter -n spark
```

### Test with a Spark Job

Submit a Spark Pi calculation job:

```bash
curl -X 'POST' \
  'http://localhost:8080/lighter/api/batches' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "Spark PI",
  "file": "/home/app/spark/examples/jars/spark-examples_2.12-3.5.6.jar",
  "mainClass": "org.apache.spark.examples.SparkPi",
  "args": ["100"]
}'
```

### Check Job Status

List all jobs:

```bash
curl http://localhost:8080/lighter/api/batches
```

### Watch Spark Driver Pods

```bash
kubectl get pods -n spark -w
```

## Configuration

### Environment Variables

You can customize the setup using environment variables:

- `KIND_CLUSTER_NAME`: Name of the Kind cluster (default: `lighter-test`)
- `LIGHTER_IMAGE`: Docker image name (default: `lighter:test`)

Example:

```bash
export KIND_CLUSTER_NAME=my-cluster
export LIGHTER_IMAGE=lighter:custom
./setup-kind.sh
```

### Spark Configuration

The Lighter deployment includes default Spark configurations:
- Kubernetes mode enabled
- Maximum 15 running jobs
- Uses `lighter` service account for Spark pods
- 10s interval for tracking running sessions

You can modify these in the `deploy-lighter-to-kind.sh` script or by editing the deployed resources:

```bash
kubectl edit deployment lighter -n spark
```

## Troubleshooting

### Pod not starting

Check pod events:
```bash
kubectl describe pod -l run=lighter -n spark
```

### Image pull issues

Ensure the image was loaded into Kind:
```bash
docker exec -it lighter-test-control-plane crictl images | grep lighter
```

### Port already in use

If port 8080 is already in use, you can use port-forward instead:
```bash
kubectl port-forward -n spark svc/lighter 8888:8080
```

Then access Lighter at http://localhost:8888/lighter/

### Spark jobs failing

Check the Spark driver pod logs:
```bash
kubectl logs -n spark <spark-driver-pod-name>
```

Verify RBAC permissions:
```bash
kubectl auth can-i create pods --as=system:serviceaccount:spark:lighter -n spark
```

## Cleanup

To remove all resources and the Kind cluster:

```bash
./cleanup-kind.sh
```

This will:
- Delete the Kind cluster
- Optionally remove the Docker image

## Architecture

The setup creates the following resources in the Kind cluster:

```
spark namespace
├── ServiceAccount: lighter
├── Role: lighter (pod/service/configmap permissions)
├── RoleBinding: lighter
├── Service: lighter (NodePort 30080 → 8080)
└── Deployment: lighter (1 replica)
```

When Lighter runs Spark jobs, it creates:
- Driver pods in the `spark` namespace
- Executor pods as needed
- ConfigMaps for Spark configuration

## About Spark

Apache Spark is included in the Lighter Docker image and is downloaded during the build process. The image contains:
- Spark 3.5.6 binaries with Hadoop 3
- Example JARs for testing
- Spark configuration templates

No separate Spark installation is required for this setup.

## Additional Resources

- [Lighter Documentation](../README.md)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Apache Spark on Kubernetes](https://spark.apache.org/docs/latest/running-on-kubernetes.html)
- [Lighter Kubernetes Guide](../docs/kubernetes.md)
