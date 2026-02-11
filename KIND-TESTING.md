# Quick Reference: Testing Lighter with Kind

This is a quick reference for the complete testing setup. For detailed documentation, see [TESTING.md](./TESTING.md).

## Prerequisites

Install these tools before starting:
- Docker (20.10+)
- Kind (Kubernetes in Docker)
- kubectl (Kubernetes CLI)

## Quick Start (3 commands)

```bash
# 1. Create Kind cluster
./setup-kind.sh

# 2. Build and load Lighter image
docker build -t lighter:test . && ./load-image-to-kind.sh

# 3. Deploy Lighter to Kubernetes
./deploy-lighter-to-kind.sh
```

Access Lighter at: http://localhost:8080/lighter/

## Alternative: Using Docker Compose

```bash
# Setup cluster
./setup-kind.sh

# Build using docker-compose
docker compose -f docker-compose.test.yml --profile build up

# Load and deploy
./load-image-to-kind.sh && ./deploy-lighter-to-kind.sh
```

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `setup-kind.sh` | Creates a Kind cluster for testing |
| `load-image-to-kind.sh` | Loads Lighter image into Kind |
| `deploy-lighter-to-kind.sh` | Deploys Lighter to the cluster |
| `cleanup-kind.sh` | Removes cluster and optionally the image |
| `test-setup.sh` | Validates the complete setup |
| `demo-workflow.sh` | Interactive demo of the full workflow |

## Test with a Spark Job

```bash
# Submit Spark Pi example
curl -X POST http://localhost:8080/lighter/api/batches \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Spark PI",
    "file": "/home/app/spark/examples/jars/spark-examples_2.12-3.5.6.jar",
    "mainClass": "org.apache.spark.examples.SparkPi",
    "args": ["100"]
  }'

# Check job status
curl http://localhost:8080/lighter/api/batches

# Watch Spark pods being created
kubectl get pods -n spark -w
```

## Troubleshooting

```bash
# Check Lighter logs
kubectl logs -f deployment/lighter -n spark

# Check all resources
kubectl get all -n spark

# Port-forward if NodePort doesn't work
kubectl port-forward -n spark svc/lighter 8080:8080
```

## Cleanup

```bash
./cleanup-kind.sh
```

## What's Included?

- **Apache Spark 3.5.6**: Included in the Lighter Docker image
- **Hadoop 3**: Bundled with Spark
- **Kubernetes**: Running via Kind
- **Lighter**: Application for Spark job management

No separate Spark installation needed - everything is containerized!

## For More Details

See [TESTING.md](./TESTING.md) for comprehensive documentation including:
- Detailed setup instructions
- Configuration options
- Advanced usage examples
- Architecture overview
- Complete troubleshooting guide
